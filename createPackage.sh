#!/bin/sh

SUBDIRECTORY_OK=Yes

OPTIONS_SPEC="\
createPackage [options] <version> <outputDir>

Creates a source tar-ball for a given <version> in <outputDir>.

The <version> argument requires that a git tree-ish object with the name
v<version> exists (i.e. a tag named e.g. v0.1.0).  If no such tag exists, you
can specify -c and the current HEAD will be tagged as v<version>. The output is
named <outputDir>/unity-lens-vpn-<version>.tar.gz and a detached signature is
created using the users default GPG-key in
<outputDir>/unity-lens-vpn-<version>.tar.gz.sig (can be overriden using -s).
Further the md5 and sha1 digests are computed and placed in
<outputDir>/unity-lens-vpn-<version>.tar.gz.md5 and
<outputDir>/unity-lens-vpn-<version>.tar.gz.sha1, respectively.
--
c,create-tag Create a tag named v<version> and sign it with the default GPG-key.
t,tag-key=   If -c is used, specify a different GPG-key ID to sign.
m,tag-msg=   Use the given tag-message if -c is specified instead of prompting.
s,sign-key=  Sign the tar-ball with the specified, non-default GPG-key."

. "$(git --exec-path)/git-sh-setup"

cd_to_toplevel

CREATE_TAG=no
CUSTOM_TAG_KEY=
TAG_MSG=
SIGN_KEY=
VERSION=
OUTPUT_DIR=

while [ $# -gt 0 ]; do
  case "$1" in
     -c|--create-tag)
        CREATE_TAG=yes
        shift
        ;;
     -t|--tag-key)
        [ $# -lt 2 ] && die "-t requires an argument"
        CUSTOM_TAG_KEY="$2"
        shift 2
        ;;
     -m|--tag-msg)
        [ $# -lt 2 ] && die "-t requires an argument"
        TAG_MSG="$2"
        shift 2
        ;;
     -s|--sign-key)
        [ $# -lt 2 ] && die "-t requires an argument"
        SIGN_KEY="--default-key $2"
        shift 2
        ;;
     --)
        [ $# -lt 3 ] && die "version and output directory are required"
        VERSION="$2"
        OUTPUT_DIR="$3"
        shift 3
        break
        ;;
  esac
done

if [ -z "$VERSION" -o -z "$OUTPUT_DIR" ]; then
   die "Version and output directory arguments are required"
fi

if ! [ -d "$OUTPUT_DIR" -a -w "$OUTPUT_DIR" ]; then
   die "The output directory '$OUTPUT_DIR' does not exist or is not writeable"
fi

for ext in "" .sig .md5 .sha1; do
   if [ -e "$OUTPUT_DIR/unity-lens-vpn-$VERSION.tar.gz$ext" ]; then
      die "The output file $OUTPUT_DIR/unity-lens-vpn-$VERSION.tar.gz$ext already exists" >&2
   fi
done

# create the tag if requested
if [ "$CREATE_TAG" = "yes" ]; then
   if git rev-list --max-count=1 --quiet --tags "v$VERSION" > /dev/null 2>&1; then
      die "Cannot create tag v$VERSION, it already exists"
   fi
   GIT_TAG_OPTS=
   if [ -n "$CUSTOM_TAG_KEY" ]; then
      GIT_TAG_OPTS="$GIT_TAG_OPTS -u $CUSTOM_TAG_KEY"
   else
      GIT_TAG_OPTS="$GIT_TAG_OPTS -s"
   fi
   if [ -n "$TAG_MSG" ]; then
      GIT_TAG_OPTS="$GIT_TAG_OPTS -m '$TAG_MSG'"
   fi
   echo "Creating tag 'v$VERSION'"
   eval "git tag $GIT_TAG_OPTS v$VERSION"
fi

# create the tar-ball
echo "Creating the tar ball"
TMP=`mktemp -d -t unity-lens-vpn-XXXX` || die "Failed to create temporary directory"
git archive --format=tar --prefix=unity-lens-vpn-$VERSION/ v$VERSION > \
  $TMP/unity-lens-vpn-$VERSION.tar || die "Failed to create tar file"

# create HTML README
echo "Creating HTML docs and adding them to the tar-ball"
mkdir $TMP/unity-lens-vpn-$VERSION
cat > $TMP/unity-lens-vpn-$VERSION/README.html << EOF
<html>
<head>
</head>
<body>
$(git show v$VERSION -- README | markdown README || die "Markdown failed")
</body>
</html>
EOF
tar -C $TMP -rf $TMP/unity-lens-vpn-$VERSION.tar unity-lens-vpn-$VERSION

echo "Compressing the tar ball"
gzip --best $TMP/unity-lens-vpn-$VERSION.tar || die "Failed to compress the tar ball"
mv $TMP/unity-lens-vpn-$VERSION.tar.gz $OUTPUT_DIR/unity-lens-vpn-$VERSION.tar.gz || \
  die "Failed to place the compressed tar ball in '$OUTPUT_DIR'"
rm -rf $TMP || die "Failed to remove the temporary directory '$TMP'"

# sign the tar-ball
echo "Signing the tar ball"
gpg --armor -o $OUTPUT_DIR/unity-lens-vpn-$VERSION.tar.gz.sig $SIGN_KEY \
  --sign --detach-sign $OUTPUT_DIR/unity-lens-vpn-$VERSION.tar.gz || \
  die "Failed to sign the tar ball"

# create md5 and sha1 sums
echo "Computing checksums of the tar ball"
(cd $OUTPUT_DIR; openssl md5 -out unity-lens-vpn-$VERSION.tar.gz.md5 unity-lens-vpn-$VERSION.tar.gz)
(cd $OUTPUT_DIR; openssl sha1 -out unity-lens-vpn-$VERSION.tar.gz.sha1 unity-lens-vpn-$VERSION.tar.gz)
