# Project Scaffolding Automation

This repository contains scripts and templates to quickly scaffold client-side and server-side applications.

## Features

### Client-Side Scaffolding

- Create Vite projects with Tailwind CSS and ESLint pre-configured.
- Automates:
  - Dependency installation
  - Tailwind CSS setup
  - ESLint configuration
  - Git repository initialization

### Server-Side Scaffolding

- Create NestJS projects with ESLint and Prettier pre-configured.
- Automates:
  - Project creation using Nest CLI
  - Dependency installation
  - ESLint and Prettier configuration
  - Git repository initialization

## File Structure

```plaintext
./
├── client-side-scaffolding/
│   ├── eslint.config.js
│   ├── my-client-app-cheatsheet.txt
│   ├── my-client-help.txt
│   └── tailwind.config.js
├── my-client-app.bash
├── my-nest-app.bash
├── server-side-scaffolding/
│   ├── my-server-help.txt
│   ├── nest-cli.json
│   ├── package.json
│   ├── pnpm-lock.yaml
│   ├── tsconfig.build.json
│   └── tsconfig.json
```

## Usage

### Client-Side Setup

1. Run the script:

   ```bash
   ./my-client-app.bash --project-name <project-name> --app-type vite
   ```

2. Follow the prompts to configure:

   - Tailwind CSS
   - ESLint
   - Git

### Server-Side Setup

1. Run the script:

   ```bash
   ./my-nest-app.bash --project-name <project-name>
   ```

2. Follow the prompts to configure:

   - ESLint
   - Prettier
   - Git

## Dependencies

- **Client-Side**:  
  [pnpm](https://pnpm.io), [Vite](https://vitejs.dev), [Tailwind CSS](https://tailwindcss.com)
- **Server-Side**:  
  [pnpm](https://pnpm.io), [NestJS CLI](https://nestjs.com/), [ESLint](https://eslint.org), [Prettier](https://prettier.io)
