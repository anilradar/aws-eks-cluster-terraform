#EKS cluster creation using terraform

# ----------------------------Cluster_Nodes------------------------------#

resource "aws_iam_role" "eks-cluster-iam-role" {
  name = "test-eks-cluster-iam-role"

  path = "/"

  assume_role_policy = <<-EOF
                            {
                                "Version": "2012-10-17",
                                "Statement": [
                                    {
                                        "Effect": "Allow",
                                        "Principal": {
                                            "Service": "eks.amazonaws.com"
                                        },
                                        "Action": "sts:AssumeRole"
                                        }
                                ]
                            }
                        EOF

}


resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-cluster-iam-role.name
}

resource "aws_eks_cluster" "test-eks-cluster" {
  name     = "test-eks-cluster-01"
  version  = "1.24"
  role_arn = aws_iam_role.eks-cluster-iam-role.arn

  vpc_config {
    subnet_ids = [var.subnet_id_1, var.subnet_id_2, var.subnet_id_3]
  }

  depends_on = [
    aws_iam_role.eks-cluster-iam-role,
  ]
}
#----------------------------------Worker_Nodes-------------------------------#

resource "aws_iam_role" "eks-worker-node-iam-role" {
  name = "test-eks-worker-node-iam-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-worker-node-iam-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-worker-node-iam-role.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.eks-worker-node-iam-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-worker-node-iam-role.name
}

resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.test-eks-cluster.name
  node_group_name = "test-eks-workers-node-group"
  node_role_arn   = aws_iam_role.eks-worker-node-iam-role.arn
  subnet_ids      = [var.subnet_id_1, var.subnet_id_2, var.subnet_id_3]
  instance_types  = ["t3.micro"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    #aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}