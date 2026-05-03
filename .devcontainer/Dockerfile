FROM mcr.microsoft.com/powershell:latest

# Install system tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    fontconfig \
    ca-certificates \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Remove any global PowerShell profile that may contain host/root-specific prompt config
RUN rm -f /opt/microsoft/powershell/7/profile.ps1

# Install Node.js 20 required by Claude Code
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell modules
RUN pwsh -NoProfile -Command " \
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name Pester             -Force -Scope AllUsers; \
    Install-Module -Name Az                 -Force -Scope AllUsers; \
    Install-Module -Name PSReadLine         -Force -Scope AllUsers; \
    Install-Module -Name Terminal-Icons     -Force -Scope AllUsers; \
    Install-Module -Name PSRule.Rules.Azure -Repository PSGallery -Scope AllUsers -Force"

# Install Claude Code via npm
RUN npm install -g @anthropic-ai/claude-code