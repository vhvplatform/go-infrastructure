# Infrastructure Diagrams

This directory contains PlantUML diagrams documenting the infrastructure architecture, network design, deployment flows, and component relationships.

## 📋 Available Diagrams

### 1. Architecture Diagram (`architecture.puml`)

**Overview**: High-level system architecture showing all major components and their relationships.

**Contents**:
- Google Cloud Platform resources
- Google Kubernetes Engine (GKE) cluster
- MongoDB Atlas database cluster
- Container registry and storage
- Monitoring and observability stack
- GitOps configuration with ArgoCD

**Key Features Highlighted**:
- Multi-namespace organization
- Auto-scaling capabilities
- High availability setup
- Workload Identity integration

### 2. Network Diagram (`network.puml`)

**Overview**: Detailed network architecture including VPC, subnets, and connectivity.

**Contents**:
- VPC network topology
- Subnet configuration
- IP address ranges
- Secondary IP ranges for pods and services
- Load balancer setup
- Cloud NAT and routing
- Firewall rules
- MongoDB Atlas network peering

**Security Features**:
- Network segmentation
- Private endpoints
- IP whitelisting
- TLS encryption

### 3. Deployment Diagram (`deployment.puml`)

**Overview**: CI/CD pipeline and deployment workflows.

**Contents**:
- GitHub Actions CI pipeline
- Build and test phases
- Development deployment flow
- Staging deployment flow
- Production deployment flow
- Terraform infrastructure deployment
- GitOps with ArgoCD

**Deployment Strategies**:
- Rolling updates for dev
- Blue-green deployment for production
- Canary deployments
- Automated rollback mechanisms

### 4. Component Diagram (`component.puml`)

**Overview**: Detailed component relationships and interactions.

**Contents**:
- Microservices architecture
- API Gateway and routing
- Authentication and authorization
- Data layer (MongoDB + Redis)
- Service mesh integration
- Monitoring and observability
- CI/CD components

**Patterns Shown**:
- Service-to-service communication
- Data replication
- Caching strategy
- Secret management
- Configuration management

## 🎨 Viewing the Diagrams

### Online Viewers

#### PlantUML Online Editor
1. Go to [PlantUML Web Server](http://www.plantuml.com/plantuml/uml/)
2. Copy the content of any `.puml` file
3. Paste and view the rendered diagram

#### VS Code Extension
1. Install the "PlantUML" extension
2. Open any `.puml` file
3. Press `Alt+D` to preview

### Local Rendering

#### Using PlantUML CLI

```bash
# Install PlantUML (requires Java)
# macOS
brew install plantuml

# Ubuntu/Debian
sudo apt-get install plantuml

# Generate PNG images
plantuml docs/diagrams/*.puml

# Generate SVG images (better for web)
plantuml -tsvg docs/diagrams/*.puml

# Generate all formats
plantuml -tpng -tsvg docs/diagrams/*.puml
```

#### Using Docker

```bash
# Generate PNG images
docker run --rm -v $(pwd):/data plantuml/plantuml docs/diagrams/*.puml

# Generate SVG images
docker run --rm -v $(pwd):/data plantuml/plantuml -tsvg docs/diagrams/*.puml
```

#### Using VS Code

1. Install "PlantUML" extension
2. Install "Markdown Preview Enhanced" extension
3. Create a markdown file with:
   ```markdown
   # Architecture
   
   ![Architecture](./architecture.puml)
   ```
4. Preview the markdown file

### Batch Generation Script

Create a script `generate-diagrams.sh`:

```bash
#!/bin/bash
# Generate all diagrams in PNG and SVG formats

DIAGRAMS_DIR="docs/diagrams"
OUTPUT_DIR="docs/diagrams/output"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate PNG
plantuml -tpng -o "$OUTPUT_DIR" "$DIAGRAMS_DIR"/*.puml

# Generate SVG
plantuml -tsvg -o "$OUTPUT_DIR" "$DIAGRAMS_DIR"/*.puml

echo "Diagrams generated in $OUTPUT_DIR"
```

## 📝 Editing Diagrams

### PlantUML Syntax Basics

#### Components
```plantuml
component "Component Name" as CompAlias
package "Package Name" {
    component "Nested Component"
}
```

#### Relationships
```plantuml
ComponentA --> ComponentB : Description
ComponentA ..> ComponentB : Dotted line
ComponentA -up-> ComponentB : Direction
```

#### Colors and Styling
```plantuml
!define CUSTOM_COLOR #E3F2FD
component "Name" as Comp #E3F2FD
skinparam backgroundColor #FFFFFF
```

#### Notes
```plantuml
note right of Component
  Additional information
  about the component
end note
```

### Best Practices

1. **Use Meaningful Names**: Choose descriptive names for components
2. **Add Colors**: Use colors to group related components
3. **Include Notes**: Add notes to explain complex relationships
4. **Keep It Clean**: Don't overcrowd diagrams
5. **Version Control**: Commit diagram source files, not just images
6. **Update Regularly**: Keep diagrams in sync with actual infrastructure

## 🔄 Updating Diagrams

When infrastructure changes:

1. **Update the `.puml` file** with changes
2. **Regenerate images** if needed
3. **Test the syntax**:
   ```bash
   plantuml -syntax docs/diagrams/your-diagram.puml
   ```
4. **Preview changes** before committing
5. **Commit both source and images** (if applicable)
6. **Update this README** if adding new diagrams

## 📚 PlantUML Resources

- [Official PlantUML Documentation](https://plantuml.com/)
- [PlantUML Language Reference](https://plantuml.com/guide)
- [Component Diagram Syntax](https://plantuml.com/component-diagram)
- [Deployment Diagram Syntax](https://plantuml.com/deployment-diagram)
- [Color Reference](https://plantuml.com/color)
- [PlantUML Examples](https://real-world-plantuml.com/)

## 🎯 Diagram Conventions

### Colors

- **#E3F2FD** (Light Blue): Cloud services (GCP)
- **#326CE5** (Blue): Kubernetes components
- **#13AA52** (Green): Database services
- **#FF6F00** (Orange): Monitoring services
- **#FFF3E0** (Light Orange): CI/CD components
- **#E8F5E9** (Light Green): Network components

### Naming Conventions

- Use PascalCase for component names
- Use snake_case for file names
- Use descriptive aliases in diagrams
- Group related components in packages

### Layout Tips

- Use `up`, `down`, `left`, `right` for directional arrows
- Group related components in packages
- Use notes for additional context
- Keep diagrams focused on one aspect

## 🆘 Troubleshooting

### Issue: Diagram won't render

**Solution**: Check for syntax errors:
```bash
plantuml -syntax docs/diagrams/your-diagram.puml
```

### Issue: Output is too large

**Solution**: Split into multiple diagrams or use:
```plantuml
scale 0.8
```

### Issue: Arrows overlap

**Solution**: Use explicit directions:
```plantuml
A -right-> B
B -down-> C
```

### Issue: Text is cut off

**Solution**: Increase margin:
```plantuml
skinparam padding 10
```

## 🤝 Contributing

When adding or updating diagrams:

1. Follow the existing style and color scheme
2. Test rendering before committing
3. Update this README with new diagrams
4. Include notes explaining key features
5. Keep diagrams simple and focused

## 📄 License

These diagrams are part of the go-infrastructure project. See [LICENSE](../../LICENSE) for details.
