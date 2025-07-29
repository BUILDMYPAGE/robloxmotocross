# Copilot Instructions for Roblox Motocross Racing Game

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

This is a Roblox game development project using Lua scripting. The project follows Roblox's client-server architecture with proper separation of concerns:

## Project Structure
- `src/server/` - Server-side scripts (ReplicatedStorage, ServerStorage, ServerScriptService)
- `src/client/` - Client-side scripts (StarterGui, StarterPlayer)
- `src/shared/` - Shared modules and configurations

## Coding Guidelines
- Use proper Roblox Lua conventions and best practices
- Implement RemoteEvents and RemoteFunctions for client-server communication
- Use proper error handling with pcall/xpcall
- Follow object-oriented programming patterns where appropriate
- Use Roblox services properly (Players, Workspace, ReplicatedStorage, etc.)
- Implement proper physics using Constraints and Attachments
- Use efficient networking to minimize lag in multiplayer scenarios

## Game-Specific Instructions
- Focus on realistic motocross physics with proper suspension and balance
- Implement efficient checkpoint and race tracking systems
- Ensure multiplayer compatibility and prevent exploits
- Use proper cleanup patterns to prevent memory leaks
- Implement smooth camera controls for motocross gameplay
