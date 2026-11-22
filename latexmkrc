# Tracked edits for ECE 563/564.
# Before every compile, compare each saved draft with the current section:
#   sections/NAME_ai_v0.tex  (AI draft, saved unchanged)  vs  sections/NAME.tex
#   sections/NAME_v1.tex     (an earlier version you kept) vs  sections/NAME.tex
# and write the result to sections/NAME_ai_v0_diff.tex or sections/NAME_v1_diff.tex.
# Print it in the PDF with \trackededits{NAME_ai_v0} or \trackededits{NAME_v1}.

sub generate_tracked_diffs {
    my $needs_rebuild = 0;
    my $pdf_mtime = (-e 'main.pdf') ? (stat('main.pdf'))[9] : undef;

    foreach my $old (glob('sections/*_ai_v0.tex sections/*_v1.tex')) {
        next if $old =~ /_diff\.tex$/;
        (my $base = $old) =~ s/_(ai_v0|v1)\.tex$/.tex/;
        next unless -e $base;
        (my $diff = $old) =~ s/\.tex$/_diff.tex/;

        my $existed = (-e $diff);
        if ($existed && -s $diff) {
            my $diff_mtime = (stat($diff))[9];
            my $old_mtime  = (stat($old))[9];
            my $base_mtime = (stat($base))[9];
            if ($diff_mtime >= $old_mtime && $diff_mtime >= $base_mtime) {
                $needs_rebuild = 1 if defined($pdf_mtime) && $diff_mtime > $pdf_mtime;
                next;
            }
        }

        my $tmp = "$diff.tmp.$$";
        my $rc = system("latexdiff --append-safecmd=cite '$old' '$base' > '$tmp' 2>/dev/null");
        if ($rc != 0 || !-e $tmp) {
            unlink $tmp if -e $tmp;
            next;
        }

        open my $fh_new, '<', $tmp or do { unlink $tmp; next; };
        local $/ = undef;
        my $new_content = <$fh_new>;
        close $fh_new;

        my $same = 0;
        if ($existed && open my $fh_old, '<', $diff) {
            my $old_content = <$fh_old>;
            close $fh_old;
            $same = (defined $old_content && $old_content eq $new_content);
        }

        if ($same) {
            unlink $tmp;
            my $old_mtime  = (stat($old))[9];
            my $base_mtime = (stat($base))[9];
            my $max_src    = ($old_mtime > $base_mtime) ? $old_mtime : $base_mtime;
            utime $max_src, $max_src, $diff;
        } else {
            rename $tmp, $diff or unlink $tmp;
            $needs_rebuild = 1 if !$existed || (defined($pdf_mtime) && (stat($diff))[9] > $pdf_mtime);
        }
    }
    return $needs_rebuild;
}

if (generate_tracked_diffs()) {
    # If a diff file was newly created or updated after main.pdf, main.fdb_latexmk
    # may not track it yet; remove main.pdf so latexmk rebuilds with the new diff.
    unlink 'main.pdf' if -e 'main.pdf';
}

if (defined &add_hook) {
    add_hook('before_xlatex', sub { generate_tracked_diffs(); });
}
