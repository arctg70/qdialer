#!/usr/bin/env python3
"""Generate a valid Xcode project for qdialer."""

import os

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.join(PROJECT_DIR, "qdialer")

# ── File layout ──────────────────────────────────────────────────────────────
SOURCE_FILES = [
    ("Models", "ContactModel.swift"),
    ("Models", "CallHistory.swift"),
    ("Services", "PinyinService.swift"),
    ("Services", "ContactService.swift"),
    ("ViewModels", "ContactSearchViewModel.swift"),
    ("Views", "KeyboardView.swift"),
    ("Views", "SearchBarView.swift"),
    ("Views", "ContactRowView.swift"),
    ("", "ContentView.swift"),
    ("", "qdialerApp.swift"),
]

RESOURCE_FILES = [
    "Info.plist",
    "Assets.xcassets",
]

# ── UUIDs (24 hex chars, no prefix) ─────────────────────────────────────────
U = {}
def add_uid(key):
    import hashlib, time
    h = hashlib.sha256(f"{key}_{time.time()}".encode()).hexdigest()[:24].upper()
    U[key] = h
    return h

for k in [
    "root_group", "app_group", "models_group", "services_group",
    "vms_group", "views_group", "product_ref", "native_target",
    "sources_phase", "resources_phase", "frameworks_phase",
    "config_debug", "config_release", "config_list_target", "config_list_project",
    "project_obj",
]:
    add_uid(k)

# UIDs for each source file
for grp, fn in SOURCE_FILES:
    path = os.path.join(grp, fn) if grp else fn
    add_uid(f"fr_{path}")
    add_uid(f"bf_{path}")

for rf in RESOURCE_FILES:
    add_uid(f"fr_{rf}")
    add_uid(f"bf_{rf}")

# ── OpenStep plist helpers ──────────────────────────────────────────────────
def q(s):
    """Quote a string ONLY if it contains characters that need quoting."""
    if not s:
        return s
    needs = False
    for ch in s:
        if ch in ' \t\n\r"\\{}();,=+*/%~<>@#&|^`?!$[]':
            needs = True
            break
    if needs:
        return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'
    return s

def plist_dict(d, indent):
    """Serialize a Python dict as OpenStep plist dict { key = val; ... }."""
    tabs = "\t" * indent
    inner_tabs = "\t" * (indent + 1)
    items = []
    for k in sorted(d.keys()):
        v = d[k]
        val_str = plist_value(v, indent + 1)
        items.append(f"{inner_tabs}{q(k)} = {val_str};")
    return "{\n" + "\n".join(items) + "\n" + tabs + "}"

def plist_value(v, indent=3):
    tabs = "\t" * indent
    if isinstance(v, bool):
        return "1" if v else "0"
    elif isinstance(v, int):
        return str(v)
    elif isinstance(v, str):
        return q(v)
    elif isinstance(v, list):
        if not v:
            return "()"
        items = [f"{tabs}\t{plist_value(vv, indent+1)}" for vv in v]
        return "(\n" + ",\n".join(items) + "\n" + tabs + ")"
    elif isinstance(v, dict):
        return plist_dict(v, indent)
    elif v is None:
        return ""
    else:
        return q(str(v))

def fmt(v, indent=3):
    return plist_value(v, indent)

def sanitize_uid(raw):
    """Strip non-hex chars and uppercase, keep 24 chars."""
    import re
    hex_only = re.sub(r'[^0-9A-Fa-f]', '', raw).upper()
    return hex_only[:24]

# ── Build object dictionary ─────────────────────────────────────────────────
oid = lambda k: sanitize_uid(U[k])

# Build file references and build file entries
all_source_build_files = []
all_resource_build_files = []

for grp, fn in SOURCE_FILES:
    path = os.path.join(grp, fn) if grp else fn
    fr_key = f"fr_{path}"
    bf_key = f"bf_{path}"
    all_source_build_files.append(oid(bf_key))

for rf in RESOURCE_FILES:
    # Info.plist is processed automatically — don't add to any build phase
    if rf == "Info.plist":
        continue
    bf_key = f"bf_{rf}"
    all_resource_build_files.append(oid(bf_key))

objects = {}

def add_isa(obj, isa):
    out = { "isa": isa }
    out.update(obj)
    return out

# Helper to create groups
def grp(name, children, path=None):
    d = {"children": children, "isa": "PBXGroup"}
    d["name"] = name
    if path:
        d["path"] = path
    d["sourceTree"] = "<group>"
    return d

# File references
for grp_name, fn in SOURCE_FILES:
    path = os.path.join(grp_name, fn) if grp_name else fn
    fr_id = oid(f"fr_{path}")
    ext_map = {".swift": "sourcecode.swift"}
    ext = os.path.splitext(fn)[1]
    objects[fr_id] = {
        "isa": "PBXFileReference",
        "explicitFileType": ext_map.get(ext, "text"),
        "fileEncoding": 4,
        "name": fn,
        "path": path,
        "sourceTree": "<group>",
    }

for rf in RESOURCE_FILES:
    fr_id = oid(f"fr_{rf}")
    ext = os.path.splitext(rf)[1]
    eft = "folder.assetcatalog" if ext == ".xcassets" else "text.plist.xml"
    objects[fr_id] = {
        "isa": "PBXFileReference",
        "explicitFileType": eft,
        "fileEncoding": 4,
        "name": rf,
        "path": rf,
        "sourceTree": "<group>",
    }

# Build files
for grp_name, fn in SOURCE_FILES:
    path = os.path.join(grp_name, fn) if grp_name else fn
    bf_id = oid(f"bf_{path}")
    fr_id = oid(f"fr_{path}")
    objects[bf_id] = {
        "isa": "PBXBuildFile",
        "fileRef": fr_id,
    }

for rf in RESOURCE_FILES:
    bf_id = oid(f"bf_{rf}")
    fr_id = oid(f"fr_{rf}")
    objects[bf_id] = {
        "isa": "PBXBuildFile",
        "fileRef": fr_id,
    }

# Product reference
objects[oid("product_ref")] = {
    "isa": "PBXFileReference",
    "explicitFileType": "wrapper.application",
    "name": "qdialer.app",
    "path": "qdialer.app",
    "sourceTree": "BUILT_PRODUCTS_DIR",
}

# Groups
models_children = [oid(f"fr_{os.path.join('Models', fn)}") for _, fn in SOURCE_FILES if _ == "Models"]
services_children = [oid(f"fr_{os.path.join('Services', fn)}") for _, fn in SOURCE_FILES if _ == "Services"]
vms_children = [oid(f"fr_{os.path.join('ViewModels', fn)}") for _, fn in SOURCE_FILES if _ == "ViewModels"]
views_children = [oid(f"fr_{os.path.join('Views', fn)}") for _, fn in SOURCE_FILES if _ == "Views"]

root_children = []

objects[oid("models_group")] = grp("Models", models_children)
root_children.append(oid("models_group"))

objects[oid("services_group")] = grp("Services", services_children)
root_children.append(oid("services_group"))

objects[oid("vms_group")] = grp("ViewModels", vms_children)
root_children.append(oid("vms_group"))

objects[oid("views_group")] = grp("Views", views_children)
root_children.append(oid("views_group"))

# Add source files in root dir
for grp_name, fn in SOURCE_FILES:
    if not grp_name:
        root_children.append(oid(f"fr_{fn}"))

# Add resource files to root
for rf in RESOURCE_FILES:
    root_children.append(oid(f"fr_{rf}"))

# App group (the main qdialer group)
objects[oid("app_group")] = grp("qdialer", root_children, "qdialer")

# Root group (project container)
objects[oid("root_group")] = {
    "isa": "PBXGroup",
    "children": [
        oid("app_group"),
        oid("product_ref"),
    ],
    "sourceTree": "<group>",
}

# Product ref group linking
# (already created above — skip duplicate)

# Build phases
objects[oid("sources_phase")] = {
    "isa": "PBXSourcesBuildPhase",
    "buildActionMask": 2147483647,
    "files": all_source_build_files,
    "runOnlyForDeploymentPostprocessing": 0,
}

objects[oid("resources_phase")] = {
    "isa": "PBXResourcesBuildPhase",
    "buildActionMask": 2147483647,
    "files": all_resource_build_files,
    "runOnlyForDeploymentPostprocessing": 0,
}

objects[oid("frameworks_phase")] = {
    "isa": "PBXFrameworksBuildPhase",
    "buildActionMask": 2147483647,
    "files": [],
    "runOnlyForDeploymentPostprocessing": 0,
}

# Native target
objects[oid("native_target")] = {
    "isa": "PBXNativeTarget",
    "name": "qdialer",
    "productName": "qdialer",
    "productReference": oid("product_ref"),
    "productType": "com.apple.product-type.application",
    "buildConfigurationList": oid("config_list_target"),
    "buildPhases": [
        oid("sources_phase"),
        oid("frameworks_phase"),
        oid("resources_phase"),
    ],
    "buildRules": [],
    "dependencies": [],
}

# Build configurations
bs_debug = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "qdialer/Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Smart Dialer",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "LD_RUNPATH_SEARCH_PATHS": [
        "$(inherited)",
        "@executable_path/Frameworks",
    ],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.qdialer.app",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SDKROOT": "iphoneos",
    "SUPPORTED_PLATFORMS": "iphonesimulator iphoneos",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "6.0",
    "TARGETED_DEVICE_FAMILY": "1",
    "ALWAYS_SEARCH_USER_PATHS": "NO",
}
bs_release = dict(bs_debug)

objects[oid("config_debug")] = {
    "isa": "XCBuildConfiguration",
    "buildSettings": bs_debug,
    "name": "Debug",
}

objects[oid("config_release")] = {
    "isa": "XCBuildConfiguration",
    "buildSettings": bs_release,
    "name": "Release",
}

# Config lists
objects[oid("config_list_target")] = {
    "isa": "XCConfigurationList",
    "buildConfigurations": [oid("config_debug"), oid("config_release")],
    "defaultConfigurationIsVisible": 0,
    "defaultConfigurationName": "Release",
}

objects[oid("config_list_project")] = {
    "isa": "XCConfigurationList",
    "buildConfigurations": [oid("config_debug"), oid("config_release")],
    "defaultConfigurationIsVisible": 0,
    "defaultConfigurationName": "Release",
}

# Project
objects[oid("project_obj")] = {
    "isa": "PBXProject",
    "attributes": {
        "BuildIndependentTargetsInParallel": 1,
        "LastSwiftUpdateCheck": 1720,
        "LastUpgradeCheck": 1720,
        "TargetAttributes": {
            oid("native_target"): {
                "CreatedOnToolsVersion": "17.2",
            },
        },
    },
    "buildConfigurationList": oid("config_list_project"),
    "compatibilityVersion": "Xcode 14.0",
    "developmentRegion": "zh-Hans",
    "hasScannedForEncodings": 0,
    "knownRegions": ["en", "zh-Hans", "Base"],
    "mainGroup": oid("root_group"),
    "productRefGroup": oid("root_group"),
    "projectDirPath": "",
    "projectRoot": "",
    "targets": [oid("native_target")],
}

# ── Write pbxproj ───────────────────────────────────────────────────────────
lines = [
    "// !$*UTF8*$!",
    "{",
    "\tarchiveVersion = 1;",
    "\tclasses = {",
    "\t};",
    "\tobjectVersion = 77;",
    "\tobjects = {",
]

for key in sorted(objects.keys()):
    obj = objects[key]
    if "isa" not in obj:
        # Find which key in U produces this UID
        ukey = next((uk for uk, uv in U.items() if sanitize_uid(uv) == key), "???")
        print(f"  ⚠ Skipping object {key} (no isa, from key '{ukey}')")
        continue
    isa = obj["isa"]

    lines.append("")
    lines.append(f"\t\t{key} /* {isa} */ = {{")

    # Special order: isa first
    lines.append(f"\t\t\tisa = {isa};")

    for field_key in sorted(obj.keys()):
        if field_key == "isa":
            continue
        value = obj[field_key]
        formatted = fmt(value, indent=4)
        if formatted != "":
            lines.append(f"\t\t\t{field_key} = {formatted};")

    lines.append("\t\t};")

lines.append("\t};")
lines.append(f"\trootObject = {oid('project_obj')} /* Project object */;")
lines.append("}")

# Write to file
xcodeproj_dir = os.path.join(PROJECT_DIR, "qdialer.xcodeproj")
os.makedirs(xcodeproj_dir, exist_ok=True)
pbxproj_path = os.path.join(xcodeproj_dir, "project.pbxproj")

with open(pbxproj_path, "w") as f:
    f.write("\n".join(lines) + "\n")

print(f"✅ Created Xcode project at: {pbxproj_path}")
print(f"   Total objects: {len(objects)}")
print(f"   Source build files: {len(all_source_build_files)}")
print(f"   Resource build files: {len(all_resource_build_files)}")
