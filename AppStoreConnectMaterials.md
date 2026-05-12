# PathTrio App Store Connect Materials

Last updated: May 11, 2026

## URLs

- Support contact email: 67238615@qq.com
- Support URL EN: https://philyu8259-create.github.io/PathTrio/support-en.html
- Privacy Policy URL EN: https://philyu8259-create.github.io/PathTrio/privacy-policy-en.html
- Support URL zh-Hans: https://philyu8259-create.github.io/PathTrio/support-zh-Hans.html
- Privacy Policy URL zh-Hans: https://philyu8259-create.github.io/PathTrio/privacy-policy-zh-Hans.html
- Apple Standard Licensed Application End User License Agreement:
  https://www.apple.com/legal/internet-services/itunes/appstore/dev/stdeula/
- ASC 配置备注: 已改为 Apple 标准 EULA（不要再设置 custom EULA）。

## ASC Privacy Checklist (2026-05-12)

- 在 App Privacy 里建议勾选的数据类型：
  - Location
  - Motion & Fitness（用于 Smart Assist）
  - Health（仅可选同步场景）
- 说明模板：
  - Location: 前台/后台（仅活动记录中）记录训练路径、距离、速度等用于“核心运动跟踪”。
  - Motion & Fitness: 记录当前运动状态变化，仅用于暂停提醒、活动类型变化与异常速度提示。
  - Health: 用户开启同步后，与 Apple Health 读/写运动与 workout 相关字段。

## English Metadata

App Name:
PathTrio

Subtitle:
Walk Run Ride Tracker

Promotional Text:
Track walks, runs, and rides with GPS routes, clean stats, smart reminders, Health sync controls, and Apple Watch support.

Keywords:
walk tracker,run tracker,bike tracker,ride tracker,GPS route,workout,fitness,walking,running,cycling,pace

Description:
PathTrio helps you record walking, running, and cycling with a clean, focused workout flow.

Start a workout, choose Walk, Run, or Ride, and PathTrio records your GPS route, distance, duration, speed, pace, and estimated calories. After each workout, review your route and keep your history organized by day, month, and activity type.

Core features:
- Walk, run, and ride tracking
- GPS route recording for outdoor workouts
- Live distance, duration, speed, and pace
- Local workout history with map route review
- Optional Smart Assist reminders for pauses, activity changes, and unusual speeds
- Optional Health sync controls
- Apple Watch companion support with Pro
- CSV and GPX export with Pro

PathTrio keeps the core recording flow simple and user-controlled. Location is used only for active workout tracking, and workout records are stored locally on your device by default.

What’s New:
Initial release with walk, run, and ride tracking, GPS route recording, local history, Pro export, Health sync controls, and Apple Watch companion support.

Review Notes:
PathTrio uses location access to record outdoor workout routes, distance, speed, and pace while the user has started an active workout. Background location is used only so an active workout can continue after the screen locks when the user grants Always Allow permission. Motion and fitness access is used for optional Smart Assist reminders such as pause suggestions, activity-type change suggestions, and unusual-speed warnings. HealthKit is optional and used only when the user enables Health sync. Pro is a one-time lifetime in-app purchase with product ID `pathtrio.pro.lifetime`; it unlocks export, advanced review features, map style options, Health sync controls, and Apple Watch companion support. The app remains usable on iPhone without a paired Apple Watch.

## Simplified Chinese Metadata

App Name:
三动迹

Subtitle:
走路跑步骑行记录

Promotional Text:
用 GPS 记录走路、跑步和骑行路线，查看距离、配速、历史趋势，并可连接健康同步和 Apple Watch。

Keywords:
走路,跑步,骑行,GPS,路线记录,运动记录,配速,健身,户外,Apple Watch

Description:
三动迹是一款专注于走路、跑步和骑行的运动记录 App。

开始运动后，选择走路、跑步或骑行，三动迹会记录 GPS 路线、距离、时长、速度、配速和卡路里估算。运动结束后，你可以回看路线，并按天、按月和运动类型整理历史记录。

核心功能：
- 走路、跑步、骑行记录
- 户外 GPS 路线保存
- 实时距离、时长、速度和配速
- 本地历史记录与地图轨迹回看
- 可选智能辅助提醒：暂停、运动类型变化和异常速度
- 可选 Apple 健康同步控制
- Pro 支持 Apple Watch 伴侣功能
- Pro 支持 CSV 与 GPX 数据导出

三动迹保持手动、可控、清晰的记录流程。定位仅用于正在进行的运动记录，运动数据默认保存在你的设备本地。

What’s New:
首个版本，支持走路、跑步、骑行记录，GPS 路线、本地历史、Pro 数据导出、健康同步控制和 Apple Watch 伴侣功能。

Review Notes:
三动迹使用定位权限记录用户主动开始的户外运动路线、距离、速度和配速。后台定位仅用于用户授权后，在锁屏时继续记录正在进行的运动。运动与健身权限用于可选的智能辅助提醒，例如暂停建议、运动类型变化建议和异常速度提醒。HealthKit 为可选功能，仅在用户开启健康同步时使用。Pro 为一次性永久购买，商品 ID 为 `pathtrio.pro.lifetime`，用于解锁数据导出、进阶复盘、地图样式、健康同步控制和 Apple Watch 伴侣支持。没有配对 Apple Watch 时，iPhone 端核心功能仍可正常使用。

## Screenshot Files

6.9-inch iPhone:
- Chinese: `artifacts/app_store_previews/phone_cn/*.png`
- English: `artifacts/app_store_previews/phone_en/*.png`

6.5-inch iPhone:
- Chinese: `artifacts/app_store_previews/phone_cn_6_5/*.png`
- English: `artifacts/app_store_previews/phone_en_6_5/*.png`

13-inch iPad:
- Chinese: `artifacts/app_store_previews/ipad_cn/*.png`
- English: `artifacts/app_store_previews/ipad_en/*.png`

Apple Watch:
- Chinese: `artifacts/app_store_previews/watch_cn/*.png`
- English: `artifacts/app_store_previews/watch_en/*.png`
