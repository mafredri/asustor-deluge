#!/usr/bin/env zsh

emulate -L zsh

yaml() { shyaml $1 $2 <$setup_yaml }

if (( ! ${+commands[shyaml]} )); then
	print "shyaml required:"
	print "  pip install shyaml"
	exit 1
fi

if (( ! ${+commands[yaml2json]} )); then
	print "yamljs required:"
	print "  npm install -g yamljs"
	exit 1
fi

# Parse configuration into global vars
for key in $(yaml keys); do
	case $(yaml get-type $key) in
		sequence)
			typeset -g -a "setup_$key"
			eval "setup_$key=( \$(yaml get-values \$key) )"
			;;
		*)
			typeset -g "setup_$key"
			typeset "setup_$key"="$(yaml get-value $key)"
			;;
	esac
done

config2json() {
	local arch=$1
	setup_architecture=$arch

	# Update dynamic variables in configuration file
	dynamic_conf_vars=( package name version architecture firmware )
	config=$setup_config
	for key in $dynamic_conf_vars; do
		real_key="setup_$key"
		config=${config/${(U)key}/${(P)real_key}}
	done

	# Convert config to JSON
	yaml2json --pretty --indentation 2 - <<<$config
}
