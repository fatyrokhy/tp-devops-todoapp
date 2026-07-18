# Le VPC principal
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "todoapp-vpc"
  }
}

# Sous-reseau PUBLIC (pour le Front)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "todoapp-public-subnet"
  }
}

# Sous-reseau PRIVE (pour Back + DB)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "todoapp-private-subnet"
  }
}

# Internet Gateway (pour que le sous-reseau public sorte sur Internet)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "todoapp-igw"
  }
}

# Table de routage PUBLIQUE (route vers Internet via l'IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "todoapp-public-rt"
  }
}

# Association : sous-reseau public <-> table de routage publique
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group du FRONT
resource "aws_security_group" "front" {
  name        = "todoapp-front-sg"
  description = "SG pour instance Front Nginx et app"
  vpc_id      = aws_vpc.main.id

  # HTTP depuis Internet
  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS depuis Internet
  ingress {
    description = "HTTPS depuis Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH uniquement depuis l IP admin
  ingress {
    description = "SSH depuis admin uniquement"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    description = "Tout trafic sortant autorise"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "todoapp-front-sg"
  }
}

# Security Group du BACK
resource "aws_security_group" "back" {
  name        = "todoapp-back-sg"
  description = "SG pour l instance Back (API)"
  vpc_id      = aws_vpc.main.id

  # Seul le Front peut acceder au Back (port de l API, ex: 3000)
  ingress {
    description     = "API depuis le Front uniquement"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.front.id]
  }

    ingress {
    description     = "SSH depuis le Front uniquement bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.front.id]
  }


  egress {
    description = "Tout sortant autorise"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "todoapp-back-sg"
  }
}

# Security Group de la DB
resource "aws_security_group" "db" {
  name        = "todoapp-db-sg"
  description = "SG pour l instance DB"
  vpc_id      = aws_vpc.main.id

  # Seul le Back peut acceder a la DB (port PostgreSQL 5432, adapte selon ta DB)
  ingress {
    description     = "DB depuis le Back uniquement"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.back.id]
  }

    ingress {
    description     = "SSH depuis le Front uniquement bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.front.id]
  }

  egress {
    description = "Tout sortant autorise"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }



  tags = {
    Name = "todoapp-db-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Import de la cle publique SSH dans AWS
resource "aws_key_pair" "deployer" {
  key_name   = "todoapp-key"
  public_key = file(var.public_key_path)
}

# Instance FRONT (sous-reseau public)
resource "aws_instance" "front" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.front.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = {
    Name = "todoapp-front"
    Role = "front"
  }
}

# Instance BACK (sous-reseau prive)
resource "aws_instance" "back" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.back.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name = "todoapp-back"
    Role = "back"
  }
}

# Instance DB (sous-reseau prive)
resource "aws_instance" "db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name = "todoapp-db"
    Role = "db"
  }
}

# Elastic IP pour le NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "todoapp-nat-eip"
  }
}

# NAT Gateway, place dans le sous-reseau PUBLIC
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "todoapp-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# Table de routage PRIVEE (route vers Internet via le NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "todoapp-private-rt"
  }
}

# Association : sous-reseau prive <-> table de routage privee
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}