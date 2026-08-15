# SPDX-License-Identifier: Apache-2.0
#
# GloDroid project (https://github.com/GloDroid)
#
# Copyright (C) 2022 Roman Stratiienko (r.stratiienko@gmail.com)

#External USB Camera HAL
PRODUCT_PACKAGES += \
    android.hardware.camera.provider@2.5-external-service \

#PRODUCT_COPY_FILES += \
#    $(LOCAL_PATH)/external_camera_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/external_camera_config.xml

#Camera HAL
# NOTE: cannot gate on BOARD_LIBCAMERA_USES_MESON_BUILD here: product mk is
# parsed before BoardConfig.mk, so the variable is undefined at this point and
# the branch would never run. libcamera is the chosen camera route for the
# Surface build, so add the packages unconditionally. The raspberry-vanilla
# meson framework (glodroid/libcamera/android/Android.mk) is itself gated by
# BOARD_LIBCAMERA_USES_MESON_BUILD in BoardConfig_glodroid.mk.
PRODUCT_PACKAGES += \
    camera.libcamera libcamera libcamera-base \
    ipa_soft_simple ipa_soft_simple.so.sign uncalibrated.yaml \
    android.hardware.camera.provider@2.5-service_64

# libexif/libjpeg/libyuv vendor variants are installed automatically by
# soong (vendor_available, pulled in by the external camera provider), so
# the HAL's runtime deps resolve from /vendor without extra copies.

PRODUCT_PROPERTY_OVERRIDES += ro.hardware.camera=libcamera

PRODUCT_COPY_FILES +=  \
    frameworks/native/data/etc/android.hardware.camera.concurrent.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.concurrent.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.raw.xml \
    frameworks/native/data/etc/android.hardware.camera.external.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.external.xml \
