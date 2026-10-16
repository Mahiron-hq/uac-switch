<div align="center">

# uac-switch

**Toggle Windows User Account Control prompts with a double click, and restore the original settings exactly**
<br>
**Переключение окон контроля учётных записей Windows двойным щелчком с точным возвратом исходных настроек**

[![License](https://img.shields.io/badge/license-Apache%202.0-green?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4?style=flat-square&logo=windows&logoColor=white)](#)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE?style=flat-square&logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen?style=flat-square)](#)

**[English](#-english)** · **[Русский](#-русский)**

</div>

---

## 🇬🇧 English

Switches UAC between the stock behaviour and a mode without "Do you want to allow
this app to make changes" prompts. The values present before the first change are
saved and written back exactly as they were.

> **Warning.** Both modes weaken system protection: any program, malware included,
> gets administrator rights without your knowledge. Enable a mode only when you need
> it and restore the settings afterwards.

### Modes

| | Silent | Full |
|---|---|---|
| Enable / disable | `UAC-Silent-On.bat` / `UAC-Silent-Off.bat` | `UAC-Off.bat` / `UAC-On.bat` |
| Consent prompts | none | none |
| A program runs as administrator | only when it asks for it | always |
| "Access denied" in `Program Files` / `Windows` | possible | no |
| Microsoft Store apps | work | do not start |
| Restart | not needed | needed |

**Silent mode.** UAC stays on, but elevation requests are approved automatically.
Programs still start with standard rights until they request elevation or you pick
"Run as administrator".

**Full mode.** UAC is off. Every program an administrator starts gets full rights
at once.

### Usage

1. Download the repository and keep all files in one folder.
2. Double-click the `.bat` you need.
3. Confirm administrator rights. This is the last prompt you will see.
4. If the mode needs a restart, it begins in 15 seconds. Run `shutdown /a` to cancel it.

To undo, run `UAC-On.bat` or `UAC-Silent-Off.bat`; both do the same thing. Modes can
be switched directly without restoring in between.

#### From PowerShell

```powershell
.\Set-UacMode.ps1 -Mode NoPrompt            # silent mode
.\Set-UacMode.ps1 -Mode Disabled -Restart   # full mode, restart
.\Set-UacMode.ps1 -Mode Restore -Restart    # restore the original settings
```

Without `-Restart` the script only warns that a restart is needed.

### How it works

The script changes three values under
`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`:

| Value | Default | Silent | Full |
|---|---|---|---|
| `EnableLUA` | 1 | 1 | 0 |
| `ConsentPromptBehaviorAdmin` | 5 | 0 | 0 |
| `PromptOnSecureDesktop` | 1 | 0 | 0 |

Before the first change the current values are saved to
`%ProgramData%\UacMode\backup.json`. The backup is never overwritten by repeated runs
or mode switches. Restoring applies it and deletes it. Without a backup, Windows
defaults are applied.

A restart is needed only when `EnableLUA` changes.

### Limitations

- **System folders stay locked.** `C:\Program Files\WindowsApps`,
  `System Volume Information` and system files in `System32` are owned by
  TrustedInstaller/SYSTEM, not by administrators, so turning UAC off does not open them.
- **An administrator account is required.** A standard user is asked for an
  administrator password, and the modes do not change that user's rights.
- Antivirus software may flag scripts that disable UAC as potentially unwanted.

### Requirements

- Windows 10 or 11 (Home included)
- Windows PowerShell 5.1 (ships with Windows)

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Failure, details are shown in the window |
| 1223 | The elevation prompt was cancelled, nothing was changed |

---

## 🇷🇺 Русский

Переключает UAC между стандартным поведением и режимом без окон «Разрешить этому
приложению вносить изменения на устройстве?». Исходные настройки сохраняются перед
первым изменением и восстанавливаются в точности такими, какими были.

> **Внимание.** Оба режима ослабляют защиту системы: любая программа, в том числе
> вредоносная, получает права администратора без вашего ведома. Включайте режим,
> только когда он действительно нужен, и возвращайте настройки после работы.

### Режимы

| | Мягкий | Полный |
|---|---|---|
| Включить / выключить | `UAC-Silent-On.bat` / `UAC-Silent-Off.bat` | `UAC-Off.bat` / `UAC-On.bat` |
| Окна подтверждения | нет | нет |
| Программа получает права администратора | только если сама их запрашивает | всегда |
| «Отказано в доступе» к `Program Files` / `Windows` | возможно | нет |
| Приложения Microsoft Store | работают | не запускаются |
| Перезагрузка | не нужна | нужна |

**Мягкий режим.** UAC остаётся включённым, но запросы на повышение прав
одобряются автоматически. Программы по-прежнему запускаются с обычными правами,
пока сами не запросят повышенные (или пока вы не выберете «Запуск от имени
администратора»).

**Полный режим.** UAC выключен. Каждая программа, запущенная администратором,
сразу получает полные права.

### Использование

1. Скачайте репозиторий и сохраните все файлы в одну папку.
2. Запустите нужный `.bat` двойным щелчком.
3. Подтвердите права администратора: это окно появится в последний раз.
4. Если режим требует перезагрузки, она начнётся через 15 секунд.
   Отменить её можно командой `shutdown /a`.

Чтобы вернуть всё как было, запустите `UAC-On.bat` или `UAC-Silent-Off.bat`:
они делают одно и то же. Режимы можно переключать напрямую, без промежуточного
восстановления.

#### Запуск из PowerShell

```powershell
.\Set-UacMode.ps1 -Mode NoPrompt            # мягкий режим
.\Set-UacMode.ps1 -Mode Disabled -Restart   # полный режим с перезагрузкой
.\Set-UacMode.ps1 -Mode Restore -Restart    # восстановить исходные настройки
```

Без `-Restart` скрипт только предупредит, что нужна перезагрузка.

### Как это работает

Скрипт меняет три параметра в разделе
`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`:

| Параметр | По умолчанию | Мягкий | Полный |
|---|---|---|---|
| `EnableLUA` | 1 | 1 | 0 |
| `ConsentPromptBehaviorAdmin` | 5 | 0 | 0 |
| `PromptOnSecureDesktop` | 1 | 0 | 0 |

Перед первым изменением текущие значения сохраняются в
`%ProgramData%\UacMode\backup.json`. Эта копия не перезаписывается при повторных
запусках и переключении режимов. При восстановлении она применяется и удаляется.
Если копии нет, применяются стандартные значения Windows.

Перезагрузка нужна только при изменении `EnableLUA`.

### Ограничения

- **Системные папки остаются закрытыми.** `C:\Program Files\WindowsApps`,
  `System Volume Information` и системные файлы в `System32` принадлежат
  TrustedInstaller/SYSTEM, а не администраторам, поэтому выключение UAC доступ
  к ним не открывает.
- **Нужна учётная запись администратора.** У обычного пользователя скрипт
  попросит пароль администратора, а сами режимы на его права не повлияют.
- Антивирусы могут помечать скрипты, отключающие UAC, как потенциально
  нежелательные.

### Требования

- Windows 10 или 11 (включая Home)
- Windows PowerShell 5.1 (входит в систему)

### Коды завершения

| Код | Значение |
|---|---|
| 0 | Успешно |
| 1 | Ошибка, подробности выводятся в окне |
| 1223 | Запрос прав администратора отменён, ничего не изменено |

---

## License / Лицензия

[Apache License 2.0](LICENSE). Copyright 2026 Lev Burmistrov (Mahiron-hq).
