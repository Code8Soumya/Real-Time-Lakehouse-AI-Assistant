# Copilot Instructions

## General Principles
1. **Follow the Plan**: Always refer to and strictly follow `plan.md` for project phases and tasks.
2. **Clarify Before Acting**: If you are in confusion or unsure about a requirement, implementation detail, or next step, **ASK THE USER FIRST**. Do not make assumptions. 
3. **Update Documentation**: Once any confusion is clarified, update both `plan.md` and this `copilot-instructions.md` file accordingly so the resolution is saved.

## Documentation Management
You must maintain a `project` folder at the root of the workspace. This folder contains four crucial files that must be kept up to date as the project evolves:

1. **`project/memory.md`**: 
   - Write what is currently going on, recent completions, and immediate next steps. 
   - Keep this updated after every major task.
2. **`project/structure.md`**: 
   - Document the current directory structure, what each folder is for, and major files.
3. **`project/architecture.md`**: 
   - Describe how all the things are connected.
   - Detail how everything runs in the project (data flow, CI/CD flow, etc.).
4. **`project/critical-context.md`**: 
   - Write all the important points about this project that the AI *must* take in mind before doing any changes.
   - This prevents breaking the app (e.g., hardcoded formats, strict domain constraints).
