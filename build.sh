#!/bin/sh

### DOWNLOAD SOURCE
if [ ! -d "qpdfview" ]; then
    bzr branch lp:qpdfview
fi
###################

### DOWNLOAD BUILD DEPENDENCIES
cd qpdfview
mkdir -p build && cd build

if [ ! -e "linuxdeployqt-continuous-x86_64.AppImage" ]; then
    wget "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
    chmod a+x linuxdeployqt-continuous-x86_64.AppImage
fi

if [ ! -e "appimagetool-x86_64.AppImage" ]; then
  wget "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x appimagetool-x86_64.AppImage
fi
###################

### BUILD
qmake ../qpdfview.pro || exit 1
make -j$(nproc) || exit 1
make -j$(nproc) INSTALL_ROOT=appdir install || exit 1
###################

### COPY REQUIRED LIBS
mv appdir/usr/lib/qpdfview/libqpdfview_* appdir/usr/bin/
find appdir/usr/bin -name '*.so' -exec patchelf --set-rpath '$ORIGIN/../lib/' {} \;
###################

### COPY APPLICATION ICONS
cp -L -r /usr/share/icons/breeze/ appdir/usr/share/icons/
###################

### CREATE APPIMAGE WRAPPER
../../appimage.create.wrapper.sh || { echo "AppImage Wrapper Creation Failed" && exit 1; }
###################

### COPY DEPENDENT LIBS AND BUILD APPDIR
ARCH=x86_64 ./linuxdeployqt-continuous-x86_64.AppImage appdir/usr/share/applications/*.desktop -bundle-non-qt-libs || exit 1
###################

### CREATE APPRUN
cd appdir
rm AppRun
ln -s usr/bin/qpdfview_wrapper.sh AppRun
cd ..
###################

### CREATE APPIMAGE
./appimagetool-x86_64.AppImage appdir || exit 1
###################
