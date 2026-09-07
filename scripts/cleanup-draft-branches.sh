#!/usr/bin/env bash
# Supprime toutes les branches distantes auto/* et cursor/* (brouillons non validés).
# Garde uniquement main. À lancer depuis la racine du repo avec accès GitHub configuré.

set -euo pipefail

REMOTE="${REMOTE:-origin}"
KEEP="${KEEP:-main}"

echo "→ Récupération des branches sur $REMOTE..."
git fetch --prune "$REMOTE"

mapfile -t BRANCHES < <(
  git branch -r \
    | sed 's|^[[:space:]]*||' \
    | grep "^${REMOTE}/" \
    | grep -v "^${REMOTE}/${KEEP}$" \
    | grep -v "^${REMOTE}/HEAD" \
    | grep -E "${REMOTE}/(auto/|cursor/)" \
    | sed "s|^${REMOTE}/||"
)

if [ ${#BRANCHES[@]} -eq 0 ]; then
  echo "Aucune branche auto/* ou cursor/* à supprimer."
  exit 0
fi

echo "Branches à supprimer (${#BRANCHES[@]}) :"
printf '  - %s\n' "${BRANCHES[@]}"
echo
read -r -p "Confirmer la suppression ? [o/N] " ans
if [[ ! "$ans" =~ ^[oOyY]$ ]]; then
  echo "Annulé."
  exit 0
fi

for branch in "${BRANCHES[@]}"; do
  echo "Suppression ${REMOTE}/${branch}..."
  git push "$REMOTE" --delete "$branch"
done

echo "✅ Terminé. Branches restantes :"
git branch -r | grep -v HEAD
