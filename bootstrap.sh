set -e -x

# Find the absolute pathname of the directory with this bootstrap.sh.
DIRNAME="$(cd "$(dirname "$0")" && pwd)"

# Clone archiso if we're not ourselves in a clone.
if [ "$(basename "$DIRNAME")" != "archiso" -a ! -d ".git" ]
then
    if [ ! -d "archiso" ]
    then
        pacman -S --needed --noconfirm "git"
        git clone "git://projects.archlinux.org/archiso.git"
    fi
    exec sh "archiso/bootstrap.sh"
fi
cd "$DIRNAME"

# Remove temporary files from last time, if any.
rm -rf "out" "work"

# Install dependencies for archiso/configs/baseline.
pacman -S --needed --noconfirm "arch-install-scripts" "make" "mkinitcpio-nfs-utils" "rsync" "squashfs-tools"
# pacman -S --needed --noconfirm "dosfstools" "lynx" # Required by configs/releng.

# Install this archiso.
make -C"$DIRNAME" install

# Configure archiso/configs/baseline to PXE boot and download its root
# filesystem via HTTP.
mkdir -p "work/root-image/usr/lib/initcpio/hooks" "work/root-image/usr/lib/initcpio/install"
cp "/usr/lib/initcpio/hooks/archiso_pxe_common" "work/root-image/usr/lib/initcpio/hooks"
cp "/usr/lib/initcpio/hooks/archiso_pxe_http" "work/root-image/usr/lib/initcpio/hooks"
cp "/usr/lib/initcpio/install/archiso_pxe_common" "work/root-image/usr/lib/initcpio/install"
cp "/usr/lib/initcpio/install/archiso_pxe_http" "work/root-image/usr/lib/initcpio/install"

# Build archiso and, by side-effect, the PXE tree.
sh "$DIRNAME/configs/baseline/build.sh" -v

# Upload the PXE tree.
if [ ! -L "work/iso/arch/arch" ]
then ln -s "." "work/iso/arch/arch"
fi
rsync -avz "work/iso/arch" "rcrowley.org":"var/www/"
