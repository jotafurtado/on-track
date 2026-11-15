#!/bin/sh
# Accept the rename only when all five notes carry the new owner and none keeps the old one.
for note in alpha bravo charlie delta echo; do
  grep -Fxq 'owner: welcome-team' "notes/$note.txt" || exit 1
  if grep -Fq 'greeting-team' "notes/$note.txt"; then exit 1; fi
done
