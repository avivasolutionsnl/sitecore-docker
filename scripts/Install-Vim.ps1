# Install vim using choco
choco install -y --params="Quiet" vim

# Add vim alias to profile
Add-Content $PROFILE "New-Alias -Name vim -Value 'C:\Program Files (x86)\vim\vim80\vim.exe'"
