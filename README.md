# livejasmin-bash
livejasmin-bash lets you archive your favourite models public shows on livejasmin.com

# Requirements
 - curl to save the captured streams. Whilst wget could have been used, it leaves zero byte files on errors
 - wget to extract parameters from site
 - several standard bash functions and/or Linux commands (e.g. find, cat, grep, etc.)

# Want to support?
<a href='https://ko-fi.com/A3803R8B' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://az743702.vo.msecnd.net/cdn/kofi2.png?v=0' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

# Setup
1. Download and unpack the [code](https://github.com/dirk362/livejasmin-bash/archive/master.zip)
2. Open console and go into the directory where you unpacked the files.
3. Enable scripts to run using `chmod +x *.sh`
4. Edit `livejasmin.ini` file and set desired values for `recording_dir`, `record_cmd`, and `get_cmd`.
5. Edit `livejasmin-models.txt` and add in the exact name of the model as defined on the main livejasmin site. Several entries are present in the source file, by way of example only.

There are additional options in the `livejasmin.ini` that define other settings such as filename date formats, etc. Naming should make it clear what these relate to.

Be mindful when capturing many streams at once to have plenty of space on disk and the bandwidth available, or you'll end up dropping a lot of frames and the files will be useless.

> Note: This script will only record when models are in public. It will not record any other type of session.
Tested on Debian derivative distributions, using bash 4.3. However should work on any modern Linux distribution.

# Running & Output
To start capturing streams you need to run `./livejasmin-parse.sh`. I recommend you do this in [screen](https://www.gnu.org/software/screen/) as that'll keep running if you lose connection to the machine or otherwise close your shell.

To close all current streams being captured, you need to run `./process-livejasmin.sh`. This will close all current recordings, and clean up any left over temporary files.

You can add to your current list of models by editing `livejasmin-models.txt` and adding extra model names.
You can do the opposite, namely removing models from the `livejasmin-models.txt`. 
The file will be re-read at the defined interval and recordings adjusted in line with your changes for that model.

You can manually record, without need to add to parse file. Just run `./livejasmin-record.sh` followed by the models name, exactly as it is defined on the website.
e.g. To start recording yummymodel you would run `./livejasmin-record.sh yummymodel`
