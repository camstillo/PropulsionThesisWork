# Tracked edits for ECE 563/564.
# Before every compile, compare each saved draft with the current section:
#   sections/NAME_ai_v0.tex  (AI draft, saved unchanged)  vs  sections/NAME.tex
#   sections/NAME_v1.tex     (an earlier version you kept) vs  sections/NAME.tex
# and write the result to sections/NAME_ai_v0_diff.tex or sections/NAME_v1_diff.tex.
# Print it in the PDF with \trackededits{NAME_ai_v0} or \trackededits{NAME_v1}.

foreach my $old (glob('sections/*_ai_v0.tex sections/*_v1.tex')) {
    next if $old =~ /_diff\.tex$/;
    (my $base = $old) =~ s/_(ai_v0|v1)\.tex$/.tex/;
    next unless -e $base;
    (my $diff = $old) =~ s/\.tex$/_diff.tex/;
    system("latexdiff --append-safecmd=cite '$old' '$base' > '$diff' 2>/dev/null");
}
