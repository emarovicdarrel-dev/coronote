#!/usr/bin/env bash
# Run after "npx cap add android": fullscreen, keep-screen-on, landscape, launcher icon, version, optional signing.
set -e
APPID=$(node -p "require('./capacitor.config.json').appId")
PKGDIR="android/app/src/main/java/$(echo "$APPID" | tr . /)"
cat > "$PKGDIR/MainActivity.java" <<JAVA
package $APPID;

import android.os.Build;
import android.os.Bundle;
import android.view.WindowManager;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        immersive();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) immersive();
    }

    private void immersive() {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        if (Build.VERSION.SDK_INT >= 28) {
            WindowManager.LayoutParams lp = getWindow().getAttributes();
            lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            getWindow().setAttributes(lp);
        }
        WindowInsetsControllerCompat c = WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        c.hide(WindowInsetsCompat.Type.systemBars());
        c.setSystemBarsBehavior(WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
    }
}
JAVA
M=android/app/src/main/AndroidManifest.xml
sed -i 's/android:launchMode="singleTask"/android:launchMode="singleTask" android:screenOrientation="landscape"/' $M
grep -q screenOrientation $M || echo "WARNING: could not lock landscape"
R=android/app/src/main/res
rm -rf $R/mipmap-anydpi-v26
for p in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  d=${p%%:*}; s=${p##*:}
  for n in ic_launcher ic_launcher_round ic_launcher_foreground; do
    convert docs/icon-round.png -resize ${s}x${s} $R/mipmap-$d/$n.png
  done
done
convert -size 2732x2732 xc:'#eef2f9' docs/icon-round.png -gravity center -composite /tmp/splash.png
find $R -name 'splash.png' -exec cp /tmp/splash.png {} \;
sed -i "s/versionCode 1\$/versionCode ${GITHUB_RUN_NUMBER:-1}/" android/app/build.gradle
if [ -n "${KEYSTORE_PATH:-}" ]; then
cat >> android/app/build.gradle <<'GRADLE'

android {
    signingConfigs {
        release {
            storeFile file(System.getenv("KEYSTORE_PATH"))
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
GRADLE
fi
echo "patched $APPID"
