"""Builds Store/index.json and every manifest.json from the definitions below.

Run:  py -3 Store/build_store.py
Each plugin lives in Store/plugins/<id>/ with its code in main.js (script) or style.css (style).
"""
import json
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
AUTHOR = "Skrrt"


def t(en, ru):
    return {"en": en, "ru": ru}


def toggle(key, en, ru, default, hint=None):
    option = {"key": key, "type": "toggle", "title": t(en, ru), "default": default}
    if hint:
        option["hint"] = hint
    return option


def slider(key, en, ru, default, low, high, step, unit="", hint=None):
    option = {"key": key, "type": "slider", "title": t(en, ru), "default": default,
              "min": low, "max": high, "step": step, "unit": unit}
    if hint:
        option["hint"] = hint
    return option


def choice(key, en, ru, default, choices, hint=None):
    option = {"key": key, "type": "choice", "title": t(en, ru), "default": default,
              "choices": [{"value": v, "title": t(e, r)} for v, e, r in choices]}
    if hint:
        option["hint"] = hint
    return option


def multichoice(key, en, ru, default, choices, hint=None):
    option = {"key": key, "type": "multichoice", "title": t(en, ru), "default": default,
              "choices": [{"value": v, "title": t(e, r)} for v, e, r in choices]}
    if hint:
        option["hint"] = hint
    return option


PLUGINS = [
    {
        "id": "cookie-consent", "category": "privacy", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Cookie Consent", "Окна cookie"),
        "summary": t("Hides cookie banners or answers them for you", "Прячет окна cookie или отвечает на них за вас"),
        "description": t(
            "Cookie banners cover the page on almost every site. This plugin recognizes the popular consent platforms (OneTrust, Cookiebot, Didomi, Quantcast and more) and clicks the right button, and for everything else it looks for the banner by its text and hides it. Choose what it should do in the settings. You can turn it off for a single site from the site menu.",
            "Окна cookie закрывают страницу почти на каждом сайте. Плагин узнаёт популярные платформы согласия (OneTrust, Cookiebot, Didomi, Quantcast и другие) и нажимает нужную кнопку, а всё остальное находит по тексту и прячет. В настройках выберите, как поступать. На отдельном сайте его можно выключить из меню сайта."),
        "icon": {"symbol": "shield.lefthalf.filled", "color": "#34C759"},
        "matches": [], "excludes": [], "runAt": "start",
        "permissions": {"hosts": [], "tools": []},
        "options": [choice("mode", "When a banner appears", "Когда появляется окно", "reject",
                           [("hide", "Only hide it", "Только спрятать"),
                            ("reject", "Reject extra cookies", "Отклонить лишние cookie"),
                            ("accept", "Accept all", "Принять все")],
                           t("Hiding never changes your choice on the site. Rejecting clicks the site's own reject button.",
                             "Скрытие ничего не решает за вас. Отклонение нажимает кнопку отказа на самом сайте."))],
        "featured": True,
    },
    {
        "id": "sponsorblock", "category": "video", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("SponsorBlock", "SponsorBlock"),
        "summary": t("Skips sponsor segments in YouTube videos", "Пропускает рекламные вставки в видео YouTube"),
        "description": t(
            "Uses the community database of SponsorBlock to skip paid promotions, self promotion, subscribe reminders, intros and outros in YouTube videos. Only the first four characters of a hashed video id are sent to the server, so it never learns which video you watch.",
            "Использует общую базу SponsorBlock и пропускает платную рекламу, самопиар, просьбы подписаться, заставки и концовки в видео YouTube. На сервер уходят только первые четыре символа хэша идентификатора, поэтому он не знает, какое видео вы смотрите."),
        "icon": {"symbol": "forward.end.fill", "color": "#FF453A", "logoHost": "sponsor.ajay.app"},
        "matches": ["youtube.com"], "excludes": [], "runAt": "end",
        "permissions": {"hosts": ["sponsor.ajay.app"], "tools": []},
        "options": [
            multichoice("categories", "Skip these parts", "Что пропускать", ["sponsor", "selfpromo", "interaction"],
                        [("sponsor", "Sponsor", "Спонсор"), ("selfpromo", "Self promotion", "Самореклама"),
                         ("interaction", "Subscribe reminder", "Просьба подписаться"), ("intro", "Intro", "Заставка"),
                         ("outro", "Outro", "Концовка"), ("preview", "Preview", "Анонс")]),
            toggle("autoSkip", "Skip automatically", "Пропускать автоматически", True),
            toggle("toast", "Show a message when skipping", "Показывать сообщение при пропуске", True),
        ],
        "featured": True,
    },
    {
        "id": "youtube-ads", "category": "video", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("YouTube Ad Skipper", "Без рекламы на YouTube"),
        "summary": t("Hides ad slots and skips video ads", "Прячет рекламные блоки и пропускает рекламу"),
        "description": t(
            "Hides the ad slots on YouTube and fast-forwards the ads that play before and during videos. While an ad plays the sound is muted, and it comes back when the video starts.",
            "Прячет рекламные блоки на YouTube и перематывает рекламу до и во время видео. Пока идёт реклама, звук выключен, а когда начинается видео, он возвращается."),
        "icon": {"symbol": "play.rectangle.fill", "color": "#FF3B30", "logoHost": "youtube.com"},
        "matches": ["youtube.com"], "excludes": [], "runAt": "end",
        "permissions": {"hosts": [], "tools": []},
        "options": [toggle("autoSkip", "Skip video ads", "Пропускать рекламу в видео", True),
                    toggle("muteAds", "Mute while an ad plays", "Выключать звук во время рекламы", True)],
    },
    {
        "id": "return-youtube-dislike", "category": "video", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Return YouTube Dislike", "Дизлайки YouTube"),
        "summary": t("Shows likes and dislikes of the video", "Показывает лайки и дизлайки видео"),
        "description": t(
            "YouTube hides the dislike counter. This plugin brings it back as a small label on the video page, using data from returnyoutubedislikeapi.com. The dislike number is an estimate, like in the original extension.",
            "YouTube скрыл счётчик дизлайков. Плагин возвращает его маленькой плашкой на странице видео по данным returnyoutubedislikeapi.com. Число дизлайков приблизительное, как и в оригинальном расширении."),
        "icon": {"symbol": "hand.thumbsdown.fill", "color": "#FF9F0A", "logoHost": "returnyoutubedislike.com"},
        "matches": ["youtube.com"], "excludes": [], "runAt": "end",
        "permissions": {"hosts": ["returnyoutubedislikeapi.com"], "tools": []},
        "options": [toggle("showViews", "Show the view count too", "Показывать ещё и просмотры", False)],
    },
    {
        "id": "youtube-shorts", "category": "video", "kind": "style", "file": "style.css", "version": "1.0.0",
        "name": t("Hide YouTube Shorts", "Без Shorts на YouTube"),
        "summary": t("Removes Shorts from the feed and the menu", "Убирает Shorts из ленты и меню"),
        "description": t("Hides the Shorts shelves, tiles and the Shorts tab on YouTube so the feed shows regular videos only.",
                         "Прячет ленты, плитки и вкладку Shorts на YouTube, чтобы в ленте остались обычные видео."),
        "icon": {"symbol": "rectangle.portrait.slash", "color": "#FF453A", "logoHost": "youtube.com"},
        "matches": ["youtube.com"], "excludes": [], "runAt": "start",
        "permissions": {"hosts": [], "tools": []}, "options": [],
    },
    {
        "id": "video-speed", "category": "video", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Video Speed", "Скорость видео"),
        "summary": t("A floating control for playback speed", "Плавающая кнопка скорости воспроизведения"),
        "description": t(
            "Adds a small control to every page with a video: minus, plus and a reset by tapping the number. The speed is remembered between videos. Works on any site, not only on YouTube.",
            "Добавляет на каждую страницу с видео небольшую панель: минус, плюс и сброс нажатием на число. Скорость запоминается между видео. Работает на любых сайтах, не только на YouTube."),
        "icon": {"symbol": "speedometer", "color": "#0A84FF"},
        "matches": [], "excludes": [], "runAt": "end",
        "permissions": {"hosts": [], "tools": []},
        "options": [slider("defaultSpeed", "Default speed", "Скорость по умолчанию", 1.0, 0.25, 4.0, 0.05, "×"),
                    slider("step", "Step", "Шаг", 0.25, 0.05, 0.5, 0.05, "×"),
                    toggle("remember", "Remember the speed", "Запоминать скорость", True),
                    toggle("control", "Show the control", "Показывать панель", True)],
        "featured": True,
    },
    {
        "id": "picture-in-picture", "category": "video", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Picture in Picture", "Картинка в картинке"),
        "summary": t("Moves a video into a floating window", "Переносит видео в плавающее окно"),
        "description": t("Adds a round button on pages with a video. Tap it to keep watching in a small floating window while you use other apps.",
                         "Добавляет круглую кнопку на страницы с видео. Нажмите её, чтобы смотреть в маленьком плавающем окне, пока вы пользуетесь другими приложениями."),
        "icon": {"symbol": "pip", "color": "#5E5CE6"},
        "matches": [], "excludes": [], "runAt": "end",
        "permissions": {"hosts": [], "tools": []},
        "options": [choice("side", "Button position", "Положение кнопки", "right",
                           [("right", "Right", "Справа"), ("left", "Left", "Слева")])],
    },
    {
        "id": "reader-mode", "category": "reading", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Reader Mode", "Режим чтения"),
        "summary": t("A clean view of an article", "Чистый вид статьи без лишнего"),
        "description": t(
            "On pages that look like an article a Reader button appears. It opens the text in a calm full-screen view with your font, size and theme and without menus, banners and recommendations.",
            "На страницах, похожих на статью, появляется кнопка «Чтение». Она открывает текст в спокойном полноэкранном виде с вашим шрифтом, размером и темой, без меню, баннеров и рекомендаций."),
        "icon": {"symbol": "book.fill", "color": "#FF9F0A"},
        "matches": [], "excludes": [], "runAt": "end",
        "permissions": {"hosts": [], "tools": []},
        "options": [slider("fontSize", "Text size", "Размер текста", 19, 14, 30, 1, "pt"),
                    choice("theme", "Theme", "Тема", "auto", [("auto", "Match the app", "Как приложение"), ("light", "Light", "Светлая"),
                                                              ("sepia", "Sepia", "Сепия"), ("dark", "Dark", "Тёмная")]),
                    choice("font", "Font", "Шрифт", "serif", [("serif", "Serif", "С засечками"), ("sans", "Sans serif", "Без засечек")])],
        "featured": True,
    },
    {
        "id": "text-size", "category": "reading", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Text Size", "Размер текста"),
        "summary": t("Makes text larger or smaller on every site", "Увеличивает или уменьшает текст на всех сайтах"),
        "description": t("Scales the text of web pages from 80 to 250 percent, like the page zoom of desktop browsers.",
                         "Масштабирует текст страниц от 80 до 250 процентов, как масштаб страницы в браузерах на компьютере."),
        "icon": {"symbol": "textformat.size", "color": "#30B0C7"},
        "matches": [], "excludes": [], "runAt": "start",
        "permissions": {"hosts": [], "tools": []},
        "options": [slider("percent", "Text size", "Размер текста", 125, 80, 250, 5, "%")],
    },
    {
        "id": "night-shift", "category": "look", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Night Shift", "Ночной режим"),
        "summary": t("A warm tint that is easier on the eyes", "Тёплый оттенок, который щадит глаза"),
        "description": t("Adds a warm tint and optional dimming over every page so reading in the evening is more comfortable.",
                         "Добавляет поверх страниц тёплый оттенок и, если нужно, затемнение, чтобы вечером читать было удобнее."),
        "icon": {"symbol": "sun.haze.fill", "color": "#FF9500"},
        "matches": [], "excludes": [], "runAt": "start",
        "permissions": {"hosts": [], "tools": []},
        "options": [slider("warmth", "Warmth", "Теплота", 25, 0, 60, 1, "%"),
                    slider("dim", "Dimming", "Затемнение", 0, 0, 50, 1, "%")],
    },
    {
        "id": "black-white", "category": "look", "kind": "style", "file": "style.css", "version": "1.0.0",
        "name": t("Black and White", "Чёрно-белый режим"),
        "summary": t("Shows every page in grayscale", "Показывает страницы без цвета"),
        "description": t("Removes all color from web pages. Useful to focus on the text and to rest your eyes.",
                         "Убирает цвет со всех страниц. Помогает сосредоточиться на тексте и отдохнуть глазам."),
        "icon": {"symbol": "circle.lefthalf.filled", "color": "#8E8E93"},
        "matches": [], "excludes": [], "runAt": "start",
        "permissions": {"hosts": [], "tools": []}, "options": [],
    },
    {
        "id": "app-banners", "category": "privacy", "kind": "style", "file": "style.css", "version": "1.0.0",
        "name": t("App Banner Blocker", "Баннеры «в приложении»"),
        "summary": t("Hides \"open in the app\" banners", "Прячет баннеры «откройте в приложении»"),
        "description": t("Many sites keep asking you to install their app. This plugin hides those banners and the smart app banners of the site.",
                         "Многие сайты постоянно предлагают установить приложение. Плагин прячет такие баннеры."),
        "icon": {"symbol": "app.badge.checkmark", "color": "#AF52DE"},
        "matches": [], "excludes": [], "runAt": "start",
        "permissions": {"hosts": [], "tools": []}, "options": [],
    },
    {
        "id": "link-cleaner", "category": "privacy", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Link Cleaner", "Чистые ссылки"),
        "summary": t("Removes tracking from links", "Убирает слежку из ссылок"),
        "description": t(
            "Cleans the links on every page like ClearURLs: it removes tracking parameters such as utm_source or fbclid and unwraps redirects of Google, Yandex, VK, Facebook and Instagram so the link goes straight to the site.",
            "Чистит ссылки на страницах как ClearURLs: убирает трекинг-параметры вроде utm_source и fbclid и разворачивает редиректы Google, Яндекса, VK, Facebook и Instagram, чтобы ссылка вела прямо на сайт."),
        "icon": {"symbol": "link", "color": "#34C759"},
        "matches": [], "excludes": [], "runAt": "end",
        "permissions": {"hosts": [], "tools": []},
        "options": [toggle("stripParams", "Remove tracking parameters", "Убирать трекинг-параметры", True),
                    toggle("unwrap", "Unwrap redirect links", "Разворачивать ссылки-редиректы", True)],
    },
    {
        "id": "overlay-remover", "category": "privacy", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Overlay Remover", "Без навязчивых окон"),
        "summary": t("Removes full-screen subscribe walls", "Убирает полноэкранные окна подписки"),
        "description": t("Finds full-screen layers that cover the page (subscribe, sign in, newsletter) and removes them, then unlocks scrolling.",
                         "Находит слои, которые закрывают всю страницу (подписка, вход, рассылка), убирает их и возвращает прокрутку."),
        "icon": {"symbol": "xmark.rectangle.fill", "color": "#FF3B30"},
        "matches": [], "excludes": [], "runAt": "end",
        "permissions": {"hosts": [], "tools": []},
        "options": [choice("mode", "Check", "Проверять", "auto", [("auto", "After the page loads", "После загрузки страницы"), ("always", "All the time", "Всё время")],
                           t("Checking all the time uses a little more battery.", "Проверка всё время немного расходует батарею."))],
    },
    {
        "id": "allow-selection", "category": "tools", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Allow Copy", "Разрешить копирование"),
        "summary": t("Unlocks text selection and copying", "Разблокирует выделение и копирование"),
        "description": t("Some sites forbid selecting and copying text. This plugin removes the lock so you can select, copy and use the context menu.",
                         "Некоторые сайты запрещают выделять и копировать текст. Плагин снимает запрет: можно выделять, копировать и открывать контекстное меню."),
        "icon": {"symbol": "doc.on.clipboard", "color": "#0A84FF"},
        "matches": [], "excludes": [], "runAt": "start",
        "permissions": {"hosts": [], "tools": []}, "options": [],
    },
    {
        "id": "same-tab", "category": "tools", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Same Tab", "Ссылки в той же вкладке"),
        "summary": t("Stops links from opening new windows", "Не даёт ссылкам открываться в новых окнах"),
        "description": t("Links that ask for a new window open in the current tab, so you do not end up with dozens of tabs.",
                         "Ссылки, которые просят новое окно, открываются в текущей вкладке, и вкладок не становится десятки."),
        "icon": {"symbol": "arrow.up.right.square", "color": "#5E5CE6"},
        "matches": [], "excludes": [], "runAt": "end",
        "permissions": {"hosts": [], "tools": []}, "options": [],
    },
    {
        "id": "unstick-headers", "category": "tools", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Unstick Headers", "Открепить шапки"),
        "summary": t("Gives the screen back from sticky bars", "Возвращает место, занятое закреплёнными панелями"),
        "description": t("Bars that stay glued to the top of the page take a lot of space on a phone. This plugin turns them into normal page content.",
                         "Панели, приклеенные к верху страницы, занимают много места на телефоне. Плагин превращает их в обычное содержимое страницы."),
        "icon": {"symbol": "pin.slash", "color": "#FF9500"},
        "matches": [], "excludes": [], "runAt": "end",
        "permissions": {"hosts": [], "tools": []}, "options": [],
    },
    {
        "id": "scroll-tools", "category": "tools", "kind": "script", "file": "main.js", "version": "1.0.0",
        "name": t("Scroll Tools", "Помощник прокрутки"),
        "summary": t("Progress bar and jumps to the top and bottom", "Полоса прогресса и переходы наверх и вниз"),
        "description": t("Shows how far you have read as a thin line at the top and adds round buttons to jump to the top or to the end of the page.",
                         "Показывает, сколько прочитано, тонкой линией сверху и добавляет круглые кнопки перехода наверх и в конец страницы."),
        "icon": {"symbol": "arrow.up.arrow.down.circle.fill", "color": "#30B0C7"},
        "matches": [], "excludes": [], "runAt": "end",
        "permissions": {"hosts": [], "tools": []},
        "options": [toggle("progress", "Show the progress line", "Показывать линию прогресса", True),
                    choice("side", "Buttons", "Кнопки", "right", [("right", "Right", "Справа"), ("left", "Left", "Слева")])],
    },
]


def main():
    index = []
    for plugin in PLUGINS:
        folder = os.path.join(ROOT, "plugins", plugin["id"])
        if not os.path.isfile(os.path.join(folder, plugin["file"])):
            raise SystemExit("missing code file for " + plugin["id"])
        manifest = {k: v for k, v in plugin.items() if k != "featured"}
        manifest["author"] = AUTHOR
        manifest["format"] = 1
        with open(os.path.join(folder, "manifest.json"), "w", encoding="utf-8", newline="\n") as handle:
            json.dump(manifest, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        index.append({
            "id": plugin["id"], "version": plugin["version"], "category": plugin["category"], "kind": plugin["kind"],
            "name": plugin["name"], "summary": plugin["summary"], "icon": plugin["icon"], "author": AUTHOR,
            "featured": bool(plugin.get("featured")), "path": "plugins/" + plugin["id"],
        })
    with open(os.path.join(ROOT, "index.json"), "w", encoding="utf-8", newline="\n") as handle:
        json.dump({"format": 1, "plugins": index}, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print("built", len(index), "plugins")


if __name__ == "__main__":
    main()
