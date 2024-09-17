function staged -d 'list "staged" files detected by git'
    command git diff --staged --name-only
end
