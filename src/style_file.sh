#!/bin/bash
VERBOSE = verbose
	  DEBUG = 2
# shellcheck disable=2148
# shellcheck disable=2034
		  ORIGIN = $(pwd) /

			   [ "$TRACE" = "1" ] && set - x

			   declare - A IGNORE_EXTS
			   IGNORE_EXTS[".hex"] = 1
					   IGNORE_EXTS[".md"] = 1

#
# When DEBUG=1 print the function name currently running.
#
							   Func()
{
	local Back =
		local ARGS =

			Back = 1
#	[ -n "$@" ] && ARGS="  $@"
			       echo_dbg "...${FUNCNAME[$Back]}()${ARGS}"
}

#
# Set the color variables or unset them.  Arg1 = ""
# or 1 sets them and arg1 = 0 unsets them.
#
set_colors()
{
	Func
	local OnOff =
		local ColorList =

			OnOff = "$1"

				ColorList = ("RED" "REDBLK" "REDYLW" "REDBLU" "GREEN" "GRNBLK" "GRNGRN" \
					     "YELLOW" "YLWBLK" "YLWRED" "YLWGRN" "YLWBLU" "YLWLTBLU" \
					     "BLUE" "BLUYLW" "RESET")

					    if [ -n "$OnOff" ] { && [ "$OnOff" = "0" ]  ; } then

						    for var in "${ColorList[@]}" ;

do
	unset $var
	done
	return
		fi
		RED = '\033[1;31m'
# shellcheck disable=2034
		      REDBLK = '\033[1;31;40m'
# shellcheck disable=2034
			       REDYLW = '\033[1;31;43m'
					REDBLU = '\033[1;31;46m'
							GREEN = '\033[1;32m'
									GRNBLK = '\033[1;32;40m'
											GRNGRN = '\033[1;32;42m'
													YELLOW = '\033[1;33m'
															YLWBLK = '\033[1;33;40m'
																	YLWRED = '\033[1;33;41m'
																			YLWGRN = '\033[1;33;42m'
																					YLWBLU = '\033[1;33;44m'
																							YLWLTBLU = '\033[1;33;46m'
																									BLUE = '\033[1;34m'
																											BLUYLW = '\033[1;34;43m'
																													RESET = '\033[0;39;49m'
}

#
# Shortcut to send output to stderr by default.
#
echo_err()
{
	/ bin / echo - e  "$@" "${RESET}"  > & 2
}

#
# Shortcut to send output to stderr by default.
#
echo_dbg()
{
	[ "$DEBUG" != "1" ] &&return

		local i =
			local CallingFunc =
				declare - a tmp =

					CallingFunc = $ {FUNCNAME[2]}
#
# If the first character in $@ is a ':' then treat $@ as a string.
#
							tmp = ("$@")
									echo_err "${CallingFunc}() ==> ${tmp[0]#:}"
}

#
# Check for failure of a particular condition and exit if necessary.
# Arg 1:  An action to perform if the test fails. E.g. return or exit.
# Arg 2:  an expression to test bracketed by single quotes.
#         E.g. '[ "${Foo:0:1}" = " " ]'
#
# Example:
#       exit_chk exit '[ "${Foo:0:1}" = " " ]'
#  of
#       if ! exit_chk return '[ "${Foo:0:1}" != " " ]' ; then
#               echo "Foo has at least one  leading space."
#               exit 1
#       fi
#
exit_chk()
{
	Func
	local Assert =
		local Action =
			local Msg =

				Action = "$1" ; shift
	Msg = "$1" ; shift
	Assert = "$1" ; shift

	if ! eval "$Assert" ; then

echo_err "Assertion failed: ($Assert)"
echo_err "$Msg"
$Action 1
fi
return 0
}

#
# Remove all leading and/or trailing spaces from arg string.
# Actually, the shell expansion process following the echo
# below will strip off all of the spaces from the edges.
#
strip_edge_ws()
{
	Func
	local chars =
		local key =

# shellcheck disable=2206
			chars = ("$@")

				for key in "${!chars[@]}" ;

do
	echo_dbg "key: ($key), chars[$key]: ${chars[$key]}"
# shellcheck disable=2116
	chars[$key] = $(echo "${chars[$key]}")
			      done
	}

#
# Create a tmp file to be used by a 'find' call to
# operate on every file of *.[ch]. See filter_style()
#
setup_flip_hashmark()
{
	Func

	if [ -z "$1" ] ; then

	echo_err "Is this a file? ($1)?"
	return 1
	       fi
	       cat > "$1" << "EOF"
#!/bin/bash
#
# For every line that starts with some whitespace leading up to a hash (#)
# replace that set with a leading hash and a space where the original hash
# was
#
# For every instance of '*const', convert to '* const'
#
	flip_hashmark() {
		sed - i  - e '/^  *#/s/^./#/' - e '/^#  *#/s/ #/  /' \
		-e '/^\/\*/,/\*\//s/^\*/ \*/' \
		-e 's/  \*const/ \* const/g'  \
		-e 's/\([^ ]\) \*const/\1 \* const/g' $@
	}

	if [ -f "$1" ] ; then

	flip_hashmark "$@"
	fi

	EOF
	chmod + x "$1"
}

#
# This is called if no files are passed in via the command line.
# Create a set of files to process for styling.  First, look for
# staged files ready to commit.  If found, those become the set
# of files returned.
#
# If no files are staged, then look for unstaged but tracked/modified
# files.
#
# If nothing is found so far then assume this is a commit --amend
# and use the set of files for the current top most commit.
#
set_files()
{
	Func
	local AGAINST =
		local Action =
			local GIT_CMD =
				local FileCount =
					declare - a Files =

#
# Default to working on staged files in the index.
#
						Action = "diff --cached"
								[ "$1" = "unstaged" ] && Action = "diff"
										GIT_CMD = "git \$Action --name-status --diff-filter=d \$AGAINST | \
                        awk '{print \$NF}'"

#
# See if there are any staged files to check:
#
												Files = ("$(eval "$GIT_CMD")") || return 1
														[ -n "${Files[*]}" ] && echo "${Files[*]}" && return 0

#
# Finding a lack of files to process turn to the most recent
# commit and assume a commit --amend occurred.
#
																AGAINST = "HEAD^"
																		FileCount = $(git log - 1 --name - only $AGAINST | wc - l)

																				if [ "$FileCount" - gt 150 ] ; then

	echo_err - n "${RED}Too many files${RESET} to process."
	echo_err "File count: ${BLUE}$FileCount"
	return 1
	       fi

	       Files = ("$(eval "$GIT_CMD")") || return 1
			       [ -n "${Files[*]}" ] && echo "${Files[*]}" && return 0

					       return 1
}

#
# Given a file path find the repo root covering that file.
#
find_repo_root()
{
	Func
	local Here =
		declare - a Files =
			local Cmd =
				local Rv =

# shellcheck disable=2206
					Files = ("$@")
						Cmd = "git rev-parse --show-toplevel"
								(
# shellcheck disable=2164
										[ "${Files[0]#/}" != "${Files[0]}" ] && cd "$(dirname "$ {Files[0]}")"
										$Cmd 2 > / dev / null
										Rv = $ ?

												return $Rv
								)
}

#
# Apply astyle to the list of files
#
filter_style()
{
	Func
	declare - a Files =
		declare - a SRCS =
			local Results =
				local ASTYLE =
					local ASTYLE_OPTS =
						local STYLE_OPTIONS =
								local ZGLUE_OPTS_DIR =
										local TMPFILE =

												Results = $1; shift

	Files = ("$@")
# shellcheck disable=2207
		SRCS = ($(filter_for_srcfiles "${Files[@]}"))
		       [ -z "${SRCS[*]}" ] && return
#
# Look first in the local directory (ORIGIN) to see if
# astyle is local and executable.  If not then try /usr/bin
# and if that fails try ORIGIN and if THAT files return error.
# While 'which' will only report executable files it could
# report "" (nothing).
#
			       ASTYLE = $ {ORIGIN} astyle
					[ ! -x "$ASTYLE" ] &&ASTYLE = / usr / local / bin / nuttx - astyle
							[ ! -x "$ASTYLE" ] && ASTYLE = $(which astyle)
									[ ! -x "$ASTYLE" ] && echo_err "Unable to find the astyle program" && return 1
											echo_dbg "$ASTYLE will be used."

											ASTYLE_OPTS = astyle - nuttx
													STYLE_OPTIONS = $ {ORIGIN}$ {ASTYLE_OPTS}
															ZGLUE_OPTS_DIR = $HOME / astyle /
																	[ ! -f "$STYLE_OPTIONS" ] && STYLE_OPTIONS = $ZGLUE_OPTS_DIR / $ {ASTYLE_OPTS}
																			echo_dbg "$STYLE_OPTIONS will be used with astyle."

																			QUIET = '-q'
																					[ "$DEBUG"  = "1" ]  && QUIET = '-v'
																							echo_dbg "$ASTYLE $STYLE_OPTIONS"

																							[ -f "$STYLE_OPTIONS" ] || echo_err "Missing [$STYLE_OPTIONS]" || return 1

#
# style check the files to commit, quietly unless DEBUG is set.
#
# shellcheck disable=2206
																									CMD = ("$ASTYLE" "--options=$STYLE_OPTIONS" $QUIET "${SRCS[@]}")
																											echo_dbg "${CMD[@]}"

																											if ! "${CMD[@]}" ; then

echo_err "${RED}Fail"
return 1
       fi

#
# Adjust the results to account for minor variations from astyle
# Create temp script to post process files styled by astyle
#
       TMPFILE = "$(mktemp -p /tmp .cleanup_astyle.XXX)"
		 setup_flip_hashmark "$TMPFILE"

		 CMD = ("$TMPFILE" "${SRCS[@]}")
			       eval "${CMD[@]}" > "$Results"
			       rm - f "$TMPFILE"

# Remove incidental files generated by astyle and this script.
#
			       find . - type f - name "*.orig" - exec rm {} \;
}

#
# Find files for the zglue NRF domain. Primarily files
# containing /nrf* in their repo path.
#
find_files_for()
{
	Func
	local file =
		local dir =

			for file in "$@" ;

do
	dir = "$(basename "$file")"
	      if [ "${dir#/nrf*}" != "$dir" ] ; then

	echo - n "$file "
	fi
	done
}

#
# Flag the file as potentially executable and
# return true.
#
is_executable()
{
	Func
	local File =
		local True =
			local False =
				local RV =

					True = 0
					       False = 1
							       RV = $False

									       File = $1

											       if ! file - ib $File | grep ^ text > / dev / null ; then

echo_dbg "Not a text file: $1."
RV = $True
     elif [ -z "$(file $File  | sed -e '/DOS/d' | sed -e '/executable/d')" ]  ; then
	echo_dbg "A DOS or executable file.: $1."
	RV = $True
#       elif [ "${1##*.}" = "sh" ] ; then
else
#
# If a script does not have a header specifying to script executable
# to use for it then the test above will only see it as a text/plain
# file.  So, check here for typical script suffixes and return True
# if there is a match.
#
case "${1##*.}" in
		sh | csh | zsh | py | bat | pl | rb) RV = $True
				echo_dbg "Anonymous shell script: $1 <${1##*.}>"
				;;
		*) RV = $False
			;;
		esac
		fi

		echo_dbg "RV: $RV"
		return $RV
	}

#
# Remove exec permissions from files not meant for it.
#
filter_set_noexec()
{
	Func
	local File =
		local Results =

			Results = "$1"; shift
# shellcheck disable=2068

	for File in $@ ;

do
	if  is_executable "$File" ; then

continue
fi
[ -x "$File" ] &&chmod - x "$File"
	done

	return 0
}

#
# Sift through the list of files passed for any matches
# against the list of file extensions to ignore: IGNORE_EXTS[@]
#
filter_out_endings()
{
	Func $@
	local xx =

		for ifi in $@ ;

do
	xx = $(echo $ifi | sed - e 's/^.*\(\.[^.]*\)/\1/')
		     [ "${xx:0:1}" = "." ] && [ -z "${IGNORE_EXTS[$xx]}" ] && echo "$ifi" && continue
		     [ "${xx:0:1}" != "." ] && echo "$ifi" && continue
		     echo_dbg "Ignoring : $ifi" > & 2
		     done
	}

#
# Strip out excess white space at end of lines
#
filter_out_whitespace()
{
	Func
	local File =
		local Results =
			declare - a Srcs =

				Results = "$1"; shift
	Srcs = ($(filter_out_endings $@))

	       for File in "${Srcs[@]}" ;

do
	if ! file - ib $File | grep ^text > / dev / null 2 > & 1 ; then

echo_dbg "Skip $File"
continue
fi
echo_dbg "Process $File"
sed - i - e 's/[
]\ +$ //' "$File"
done
}

#
# Correct c++ commenting tokens to C99 commenting tokens.
#
filter_double_slashes()
{
Func
declare - a Files =
	declare - a SRCS =
		local Results =

			Results = $1; shift

Files = ("$@")
# shellcheck disable=2207
		SRCS = ($(filter_for_srcfiles "${Files[@]}"))

		       for File in "${SRCS[@]}" ;

do
	sed - i - e '/\/\//s/$/\*\//' - e '/\/\//s://:/\*/:' $File
	done
}

#
# Look for any code bracketed by "#if 0...#endif" and flag it.
# and remove it in case the --add flag was passed.
#
filter_if_0()
{
Func
local Results =
	declare - a Files =
		local Key =
			local Msg =

				Results = "$1"; shift
Files = ("$@")
		Key = "^[ 	]*#if[ 	]*0"
		      Msg = "XXX Please remove or rename \\'if 0\\'"

			    for i in "${Files[@]}" ;

do
	if grep "$Key" "$i" > / dev / null  2 > & 1 ; then

eval sed - i - e \'/"$Key"/i"$Msg"\' "$i"
fi
done
}

#
# Given a directory of the form "abc/" or "/abc/" and a list
# of files return the list of files NOT containing that directory
# in its path.
#
filter_out_dirs()
{
Func
echo_dbg " :: $@"
local Dir =
	local Flag =

		[ -z "$*" ] && echo_dbg "No dirs to filter out" && return

				Dir = "$1" ; shift
	filter_for_dirs "NOT" "$Dir" "$@"
}

#
# Filter for files in the zglue NRF domain. Primarily files
# containing /nrf* in their repo path.
#
filter_for_dirs()
{
	Func
	echo_dbg " :: $@"
	local file =
		local Dir =
			local A_CMD =
				local B_CMD =
					local NOT =

						[ -z "$*" ] && echo_dbg "No dirs to filter for" && return

								NOT = "for "
# The normal case: i.e. report paths containing the directory
										A_CMD = "eval echo \$file"
												B_CMD =

														if [ "$1" = "NOT" ] ; then

	NOT = "out "
	      shift
# The NOT case: i.e. Don't report paths containing
# the directory
	      echo_dbg "     Setting B_CMD ($B_CMD)"
	      B_CMD = "eval echo \$file"
		      A_CMD =
			      fi
			      Dir = "$1" ; shift
	echo_dbg "Filter ${NOT}$Dir"

	for file in "$@" ;

do
#
# If these two strings don't match then the file
# path continas the directory component.
#
	if [ "${file%${Dir}*}" != "$file" ] ; then

	$A_CMD
	echo_dbg "NOT $A_CMD"
	continue
	fi
	$B_CMD
	done
}

#
# Remove paths including files in ignored directories.
#
ignore_dirs()
{
	Func
	local Dir =
		local Limit =
			local Idx =
				declare - a RESULTS =

					Idx = 0
					      RESULTS = ($@)
							      echo_dbg "RESULTS[*] :: (${RESULTS[*]})"
#
# Init the RESULTS hash with the first dir to exclude.
#       RESULTS=( $(filter_out_dirs "${IGNORE_DIRS[$Idx]}" "$@") )
							      Limit = $(($ {#IGNORE_DIRS[@]} - 1))
									      echo_dbg "Limit ($Limit), Ignoring IGNORE_DIRS[$Idx]=${IGNORE_DIRS[$Idx]}"

									      for Idx in $(seq 0 1 $Limit) ;

	do
		echo_dbg "Ignoring IGNORE_DIRS[$Idx]=${IGNORE_DIRS[$Idx]}"
		Dir = "${IGNORE_DIRS[$Idx]}"
#
# Feed the pared down set of files back for further filtering.
		      RESULTS = ($(filter_out_dirs "$Dir" "${RESULTS[@]}"))
				done

#
# Finally, the set of files matching NONE
# of the dirs in the list of exluded dirs.
#
				echo_dbg "RESULTS[*] :: (${RESULTS[*]})"
				echo "${RESULTS[@]}"
	}

#
#
#
any_protected_dirs()
{
	declare - a files =
		declare - a OUT =

			files = ($@)

				for i in $(seq 0 1 $ {#NUTTX_PROTECTED_DIRS[@]}) ;

	do
		OUT = ($(filter_for_dirs "${NUTTX_PROTECTED_DIRS[$i]}" "${files[@]}") "${OUT[@]}")
		      done

		      if [ -z "${OUT[*]}" ] ; then

	return 1
	       fi
	       echo "${OUT[@]}"
	       return 0
}


#
# Look for externs lurking in header files.
#
filter_for_externs()
{
	declare - a Files =
		local Results =

			Results = "$1"; shift
	Files = ("$@")

		for i in "${Files[@]}" ;

do
	[ -n "${i%%*.h}" ] && continue
		grep "^extern.*;" "$i" > / dev / null 2 > & 1 && sed - i \
		-e '/^extern.*;/iXXX Remove this extern!' "$i"
		done

		return 0
	}


#
# Run all filters on the files finishing with the astyle formatting last.
#
filter_files()
{
	Func
	local RepoRoot =
		declare - a Files =
			local Results =
				local ZGLUE_OPTS_DIR =
					declare - a tmp =
						local RV =

								RV = 1

#
# Make sure this script is running from the repo root.
#
										[ "$(basename "$0")" = "pre-commit" ] && [ ! -d "$1" / .git ] && return 1

												RepoRoot = "$1"; shift
	Results = "$1" ; shift

	RESULTS = $ {RepoRoot} / $Results
# shellcheck disable=2206
		  Files = ("$@")
			  echo_dbg " === Files has ${#Files[@]} elements"
			  echo_err "${BLUE}\$1 is (${Files[0]})"

			  strip_edge_ws "${Files[@]}"

			  if [ "${Files:0:1}" = " " ] ; then

	echo_err "${YLWBLU}${Files[0]}  has a leading space"
	fi
	[ ! -f "${Files[0]}" ] &&echo_err "No files to style." &&return 0

			(
				[ -z "$RepoRoot" ] && return 1
						cd "$RepoRoot" || return 2

								for Func in $FILTER_FUNCTIONS ;
				do
					echo_dbg "$Func"
					if ! $Func "$RESULTS" "${Files[@]}" ; then
						echo_err "${RED}== $Func failed."
						fi
						RV = $((RV + $ ?))
						     done

#
# Run filter_style last as it will gather all of the diffs into one file.
#
						     if [ -n "${Files[*]}" ] ; then
							filter_style "$RESULTS" "${Files[@]}"
							fi
# Ignore error messages so they themselves do not cause a style failure.
							git diff "${Files[@]}" > "$RESULTS" 2 > / dev / null

							[ -s "$RESULTS" ] && grep "^XXX" "$RESULTS" && unset GIT_ADD
							return $RV
						)

#
# Set return value based on size of output file.
#
							[ ! -s "$RESULTS" ] && RV = 0 && echo "Remove $RESULTS" && rm - f "$RESULTS"

									return $RV
				}

#
# From a list of repo@remote tuples see if the currently local
# repo maps back to any in the list.  If it does then the local
# repo is a valid managed repo.
#
in_managed_repo()
{
	Func
	local RemoteTuple =
		local VerifyTuple =
			declare - a RemoteNames =
				local ManagedTuples =

# shellcheck disable=2207
					RemoteNames = ($(git remote))
							[ -z "${RemoteNames[*]}" ] && echo_dbg "No remote for this repo." && return 1
									ManagedTuples = ("$@")

											for name in "${RemoteNames[@]}" ;

do
# shellcheck disable=2207
	RemoteTuple = ($(git remote get - url "$name" | awk - F'/' '{print $3, $4}'))
			      RemoteTuple[0] = $ {RemoteTuple[0]# *@}
					       VerifyTuple = $ {RemoteTuple[1] % % .git}@$ {RemoteTuple[0] % % :*}

							       for tuple in "${ManagedTuples[@]}" ;

do
	if [ $tuple == $VerifyTuple ] ; then

	echo_dbg "$VerifyTuple Matched!"
	return 0
	       fi
	       done
	       done

	       return 0
}

#
# Return the file list containing only *.[ch] files
#
filter_for_srcfiles()
{
	Func
	local file =
		local tmpo =
			declare - a tmpe =

				tmpe = ("$@")
				       echo_dbg " tmpe has ${#tmpe[@]} elements"

				       for file in "${tmpe[@]}" ;

do
	tmpo = $ {file % % *.[ch]}
	       [ -n "$tmpo" ] &&echo_dbg "skipping $file" &&continue

# shellcheck disable=2153
		       [ -n "${tmpo%%/*}" ] &&file = $ {REPOROOT}$file
						     echo - n "$file "
						     echo_dbg "$file"

						     done
	}

#
# Use the output of git status to create a set of files to process.
#
git_committed()
{
	Func
	local IFS =
		local Filter1 =
			local Filter2 =

				[ "$1" = "unstaged" ] && IFS = " " && echo_dbg "Setting IFS to a space"
						Filter1 = "'/^${IFS}[AMC]/p'"
								Filter2 = "'/^${IFS}[R]/p'"
										git status - uno --porcelain = v1 | eval sed - n - e "$Filter1" - e "$Filter2" | \
												awk '{print $NF}'
}
###############  pre-commit should mostly match from here onward. ##############

#
# Turn on shell command tracing if DEBUG is "2"
#
[ "$TRACE" = "1" ] && set - x

Red = '\033[1;31m'
      Reset = '\033[0;39;49m'
##### Script personality goes below

#
# Help nessage describing the command line options
#
	      help()
{
	cat << "EOF"

	    $(basename $0): [-h] [--git] [--add] [--file | -f] [<file 1> <file2> ... ]

	style_file examines the local environment for c source files to
	apply formatting rules to.  For every file listed on the command
	line style_file will format only the *.c *.h files and generate
	a diff file, style.errs, where you are running the program from.

	A list of files may also be provided as a file containing a
	list of files.  Use the '-f <file name>' flag.

	If no files are provided on the command line then style_file
	will first examine the files staged.  If there are no files
	found then style_file examines the set of files in the moxt
	recent commit and format the source files in that check - in.

	- h |  --help       Display this message

	- g |  --git        Look to the git index and recent commits for the
		set of files to check.

		- a | --add        Run 'git add ' on the files formatted

		- f | --file       Provide the list of files to format as a file
		conbtaining the set of files to format

		- p                Refrain from checking for sacred dirs.

			+ p  <dir>         Add a directory to the protected list. May appear more
			than once on the command line to add multiple dirs.

			- I                Do not ignore any directories

			+ I  <dir>         Add a directory to the ignore list. May appear more
			than once on the command line to add multiple dirs.

			*            Files provided on the command line

			Each of these means of collecting files to process are
			mutually exclusive

			EOF
		}

#
# Parse the command line args passed in and set variables
# according to args.  Because this is wrapped into a routine
# the variables set mmust be exported from the main env.
#
set_env()
{
while [ $# -ne 0 ] ;

	do
# shellcheck disable=2207
	case "$1" in
			--add) GIT_ADD = yes;
			;;
			-c | --color - off) COLOR_OFF = 0
							;;
			-f | --file) [ ! -f "$2" ] &&echo_err "No file? [$2]" &&exit 1
				[ -f "$2" ] &&FILES = ($(sed - e 's/^[ 	]*//' "$2")) && shift
						      echo_dbg "From containing file, list of files is \\n(${FILES[*]})"

						      if [ -z "${FILES[*]}" ] ; then

						      echo_err "Failed to read files from $2"
						      exit 1
						      fi
						      [ -n "${FILES[*]}" ] &&echo_dbg "Found files."
						      ;;
			-g | --git) FILES = ($(git_committed))
					    [ -z "${FILES[*]}" ] && echo_err "No files found to process." ; exit 0
					    echo_dbg "${FILES[@]}"
					    ;;
			-h | --help) help; exit 0;
				;;
			+I)  [ ! -d "$2" ] &&echo "Not a dir: [$2]" > & 2 && help &&exit 1
				echo - n - e "Ignoring ${#IGNORE_DIRS[@]} directories\t"
			IGNORE_DIRS[$ {#IGNORE_DIRS[@]}] = "$2"
	echo    - e "Now ignoring ${#IGNORE_DIRS[@]} directories"
	echo_dbg "Ignore ${IGNORE_DIRS[*]}"
	shift
	;;
	-I)  IGNORE_DIRS = ()
			   ;;
	+p)  [ ! -d "$2" ] &&echo "Not a dir: [$2]" > & 2 && help &&exit 1
		echo - n - e "Protecting ${#NUTTX_PROTECTED_DIRS[@]} directories\t"
	NUTTX_PROTECTED_DIRS[$ {#NUTTX_PROTECTED_DIRS[@]}] = "$2"
	echo    - e "Now protecting ${#NUTTX_PROTECTED_DIRS[@]} directories"
	echo_dbg "Protect ${NUTTX_PROTECTED_DIRS[*]}"
	shift
	;;
	-p)  NUTTX_PROTECTED_DIRS = ()
				    ;;
	-w) FILES = ($(git_committed unstaged));
		[ -z "${FILES[*]}" ] &&echo_err "No files found to process." ; exit 0
	ALT = unstaged
	      ;;

	      *) if [ -f "$1" ] ; then

	FILES = ("${FILES[@]}" "$1")
		elif [ ! -f "$1" ]  ; then
		echo_err "${Red}No such file: ($1)${Reset}" &&exit 1
		elif [ "$FILE_ARGS" != "1" ] ; then
		echo_err "Unknown or unexpected arg ($1)."
		[ -f "$1" ]&& \
		echo_err "The list of files requires a preceding '--'."
		fi
		;;
		esac
		shift
		done

# In case any leading and/or trailing white space exists
		strip_edge_ws "${FILES[@]}"
	}

# In case any leading and/or trailing white space exists
[ -n "${FILES[*]}" ] &&strip_edge_ws FILES

IGNORE_DIRS = ("external/" "zmodem/" "CppUTest/" "cpput/" "uClibc++/")
	      export FILTERS_NRF = "/nrf52/ /nrf52832_dk/"
				   export FILTER_FUNCTIONS = "filter_out_whitespace filter_if_0 filter_for_externs filter_set_noexec"

						   REPO_HOST = "101.132.142.37"
								   ACTIVELY_MANAGED_REPOS = (\
										   "nuttx@$REPO_HOST" \
										   "nuttx_apps@$REPO_HOST" \
										   "auto_test@$REPO_HOST" \
										   "3rd_Party_SDK@$REPO_HOST" \
										   "fast_api@$REPO_HOST" \
											    )

										   NUTTX_PROTECTED_DIRS = ("sched/" "fs/" "mm/")

												   declare - A REPO_FILTERS
												   REPO_FILTERS[nuttx@$REPO_HOST] = "filter_if_0 filter_out_whitespace filter_for_externs"
														   REPO_FILTERS[nuttx_apps@$REPO_HOST] = "filter_if_0 filter_out_whitespace filter_for_externs"
																   REPO_FILTERS[auto_test@$REPO_HOST] = "filter_out_whitespace"
																		   REPO_FILTERS[3rd_Party_SDK@$REPO_HOST] = "filter_out_whitespace"
																				   REPO_FILTERS[fast_api@$REPO_HOST] = "filter_if_0 filter_out_whitespace filter_for_externs"

																						   if [ "$(basename "$0")" != "pre-commit" ] ; then

set_env "$@"
elif [ "$#" - ne 0 ] ; then
echo_dbg "Ignoring command line arguments"
fi
set_colors $COLOR_OFF
[ "$COLOR_OFF" = "0" ] && echo_err "${GRNGRN}=== colors should be off."

#
# At this point if no files have been provided over the command line
# make sure we are running within a repo else there will be no way
# to discover any potential files for processing.
#

if ! REPOROOT = "$(find_repo_root "$ {FILES[@]}")" ; then

# shellcheck disable=2153
	echo_err "${REDYLW}Error looking for a repo root directory."
	exit 1
	fi
	THIS_REPO = ($(git remote - v | grep fetch | sed - e 's/(.*)$//' | awk - F'/' '{print $NF}'))

#
# Check whether this repo is to be styled.
#
		    if ! in_managed_repo "${ACTIVELY_MANAGED_REPOS[@]}" ; then

		echo_dbg "This working tree is not from an actively managed repo."
		echo_dbg "Do nothing."
		exit 0
		fi
		echo_dbg "This repo is actively managed."

# shellcheck disable=2207
		[ -z "${FILES[*]}" ] &&FILES = ($(set_files "$ALT")) && echo_dbg " :: now FILES :==> ${FILES[*]}"
					       echo_dbg " 2 :: FILES :==> ${FILES[*]}"

# Filter out any paths containing exluded directories:
#
					       echo_dbg " 3 :: FILES :==> ${FILES[*]}, # ${#FILES[@]}"
					       FILES = ($(ignore_dirs "${FILES[@]}"))
						       [ "${#FILES[@]}" - eq 0 ] && echo_dbg "No files after filter for ignored dirs." && exit 0

# In case any leading and/or trailing white space exists
						       strip_edge_ws "${FILES[@]}"

						       if RES = ($(any_protected_dirs "${FILES[@]}")) ; then

			echo_err "The set of changes includes one or more protected directories:"
			echo_err "\t\t${!PROTECTED_DIRS[@]}"
			echo_err "Protected dir: ${RES[*]}"
			exit 1
			fi

#
# If there are no files to process there weren't any style errors!
#
			[ -z "${FILES[*]}" ]&& \
			echo_dbg  "${GRNGRN}\\tNo files to process."&& \
			exit 0

			[ -n "$REPOROOT" ] &&REPOROOT = "$REPOROOT" /
							echo_dbg "Repo Root :: $REPOROOT"
							rm - f style.errs $REPOROOT / style.errs

#
# If there are no SRCS to format then by default there are no style errors.
#
							echo_dbg "$SRCS" "$REPOROOT" "$ORIGIN"
							strip_edge_ws "${FILES[@]}"
							ERR_FILE = style.errs

									if ! filter_files "$REPOROOT" "$ERR_FILE" "${FILES[@]}" ; then

				[ "$DEBUG" = "1" ] && VERBOSE = --verbose
								MAIN_PHRASE = "${REDYLW}\\tNuttx style errors found,"
										PHRASEX = "left unstaged."

												if [ -n "$GIT_ADD" ] ; then

					git add "$VERBOSE" "$SRCS"
					PHRASEX = "${GRNGRN}corrected, and  staged."
						  fi
						  echo_err "$MAIN_PHRASE $PHRASEX$"
						  echo_err "${REDYLW}\\tSee style.errs in the root of this repo ($REPOROOT)."
						  tail - n 300 $ERR_FILE > & 2

						  exit 2
						  fi
						  echo_err  "${GRNGRN}\\tNo style errors found."

