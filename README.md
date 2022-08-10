# sfxctl
scripts to control swift sfx14-41g laptop.

Functions:

1. Acer mode switch, slient, normal and performance are supported like things under Winodws, also able to enable max fan speed.
2. Turn off dGPU totally by an acpi call. helpful when on battery.
3. Brightness control, helpful for Window Manager users.
4. Show power comsuption infomation reported by battery.

---

## Acer mode switch

Usages:
```
./sfx14-41g.sh [m|mode] [s|n|p|m]
```
s is Slient, n is Normal, p is Performance, m is Max fan speed.

optional dependency: ryzenadj


## Turn off dGPU

Usages:

```
./sfx14-41g.sh [g|gpu] [on|off]

```

dependency: acpi_call-dkms


## Brightness control

```
./sfx14-41g.sh [b|bl] [u|d|up|down]
```

you should resolve permission probelm yourself.

## Show power comsuption

```
./sfx14-41g.sh [p]
```
