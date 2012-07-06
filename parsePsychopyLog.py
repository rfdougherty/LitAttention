#!/usr/bin/env python

import sys,os,math,re

tr = 2.0
fsl_pre = 'fsl4.1-'

if __name__ == "__main__":
    if len(sys.argv)==2:
        in_file = sys.argv[1]
        fmri_files = None
    elif len(sys.argv)==6:
        in_file = sys.argv[1]
        fmri_files = sys.argv[2:6]
    else:
        print("ERROR: you must specify a Psychopy log file to parse!")
        sys.exit(1)

    # number of seconds of data that will be chopped off from the beginning of each block:
    start_chop_secs = 6

    with open(in_file, 'r') as f:
        # Run through the file to parse all the trial times and extract condition names.
        text_start_times = []
        text_end_times = []
        scan_start_times = []
        scan_condition_types = []
        cur_block_num = -1
        new_block_found = False
        for l in f.readlines():
            w = l.split('\t')
            if w[1]=='DATA' and w[2].startswith('Keypress: space'):
                last_space_time = float(w[0])
            elif w[1]=='EXP' and w[2].startswith('Created sequence'):
                # This marks the beginning of a block of paragraphs.
                cur_block_num = cur_block_num+1
                scan_start_times.append(last_space_time)
                text_start_times.append([])
                text_end_times.append([])
                new_block_found = True
            elif new_block_found and w[1]=='EXP' and w[2].startswith('New trial'):
                m = re.search('\'itemColor\': u\'(.*)\'}',w[2])
                if m != None:
                    scan_condition_types.append(m.groups()[0])
                new_block_found = False
            elif w[1]=='EXP' and w[2].startswith("Started presenting paragraphs"):
                text_start_times[cur_block_num].append(float(w[0]))
            elif w[1]=='EXP' and w[2].startswith("Stopped presenting paragraphs"):
                # We assume that there must be a "stop" following each start!
                text_end_times[cur_block_num].append(float(w[0]))

    # Get the unique set of condition types
    conditions = set(scan_condition_types)

    # initialize the trial_times dictionary with a slick list comprehension. :)
    trial_times = dict((i, []) for i in conditions)

    start = 0
    duration = 0
    block_duration = []
    prev_end_time = 0
    for b in range(len(scan_condition_types)):
        # we'll need the total block duration to know how to chop the timeseries:
        cur_block_duration = text_end_times[b][-1] - scan_start_times[b] - start_chop_secs
        # round up to the next nearest tr
        cur_block_duration = math.ceil(cur_block_duration/tr)*tr
        block_duration.append(cur_block_duration)
        for t in range(len(text_start_times[b])):
            start = text_start_times[b][t] - (scan_start_times[b]+start_chop_secs) + prev_end_time
            duration = text_end_times[b][t] - text_start_times[b][t]
            trial_times[scan_condition_types[b]].append("%f %f 1\n" % (start,duration))
        prev_end_time = prev_end_time + cur_block_duration

    for c in conditions:
        with open(c + '.txt','w') as f:
            f.writelines(trial_times[c])

    print "Block durations (sec): " + str(block_duration)
    print "Block durations (trs): " + str([t/tr for t in block_duration])
    print "Start chop secs: " + str(start_chop_secs)

    if fmri_files != None:
        print 'Now processing fmri data ('.join(fmri_files) + ')...'
        print 'Well... actually just printing the commands that you should run...'
        out_file = []
        for i in range(4):
            curDur = block_duration[i]
            out_file.insert(i,'/tmp/litattn_fmri' + str(i) + ' ')
            cmd = fsl_pre+"fslroi " + fmri_files[i] + " " + out_file[i] + " -1 -1 -1 -1 -1 -1 " + str(int(start_chop_secs/tr)) + " " + str(int(curDur/tr))
            print cmd

        cmd = fsl_pre+"fslmerge -t /tmp/fmri_all " + ''.join(out_file)
        print cmd
        cmd = fsl_pre+"fslreorient2std /tmp/fmri_all fmri_all"
        print cmd
        cmd = fsl_pre+"fslreorient2std " + os.path.join(os.path.dirname(fmri_files[0]),'0003_01_T1w_9mm') + " t1"
        print cmd
        cmd = fsl_pre+"bet t1 t1_brain"
        print cmd

    else:
        for i in range(4):
            curDur = block_duration[i]
            print "fslroi fmri.nii.gz fmri_chopped.nii.gz -1 -1 -1 -1 -1 -1 " + str(int(start_chop_secs/tr)) + " " + str(int(curDur/tr))

# *** TODO: the timeseries will be chopped to eliminate the dead time at the end of each block.
# Thus, the "prev_end_time" should be rounded up to the next TR.

    print 'Finished.'
    exit(0)

