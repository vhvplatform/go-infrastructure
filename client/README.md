# Client - Frontend Microservices

This directory contains ReactJS-based frontend microservices for the platform.

## Structure

```
client/
├── service-name-1/      # Frontend service 1
├── service-name-2/      # Frontend service 2
└── shared/              # Shared components and utilities
```

## Getting Started

Each frontend microservice should be a separate React application with its own:
- `package.json` - Dependencies and scripts
- `src/` - Source code
- `public/` - Static assets
- `README.md` - Service-specific documentation

## Development

```bash
cd client/service-name
npm install
npm start
```

## Build

```bash
npm run build
```

## Testing

```bash
npm test
```
