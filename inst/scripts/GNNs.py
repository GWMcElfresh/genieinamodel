import torch
import torch.nn as nn
import torch_geometric
import anndata as ad
from torch_geometric.nn import GCNConv
from torch_geometric.data import Data

# Example RNASeq-like data (nodes = genes, edges = gene interactions)
num_genes = 2000
num_samples = 32

# Simulating a simple adjacency matrix for gene interactions
edge_index = torch.randint(0, num_genes, (2, 5000), dtype=torch.long)  # 5000 edges
node_features = torch.randn((num_genes, num_samples))  # Gene expression data (nodes)

#Read AnnData

# Create a PyTorch Geometric Data object
data = Data(x=node_features, edge_index=edge_index)

# Define a simple Graph Convolutional Network (GCN)
class GCN(nn.Module):
    def __init__(self, input_dim, hidden_dim, output_dim):
        super(GCN, self).__init__()
        self.conv1 = GCNConv(input_dim, hidden_dim)
        self.conv2 = GCNConv(hidden_dim, output_dim)
    
    def forward(self, data):
        x, edge_index = data.x, data.edge_index
        x = torch.relu(self.conv1(x, edge_index))
        x = torch.relu(self.conv2(x, edge_index))
        return x

# Initialize the model
model = GCN(input_dim=num_samples, hidden_dim=64, output_dim=32)

# Loss function and optimizer
optimizer = torch.optim.Adam(model.parameters(), lr=0.01)
criterion = nn.MSELoss()

# Training loop
epochs = 50
for epoch in range(epochs):
    model.train()
    optimizer.zero_grad()
    
    # Forward pass
    output = model(data)
    
    # Here, we would compare the output to the true gene interactions
    loss = criterion(output, node_features)  # Using node features as a proxy for targets
    loss.backward()
    optimizer.step()
    
    print(f"Epoch {epoch+1}, Loss: {loss.item()}")
