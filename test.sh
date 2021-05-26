set -e
nix build -Lf . --arg count 1 --argstr benchmark 01
cp result table.html
chmod +w table.html
echo -e "\nopen 'table.html' in your browser"
