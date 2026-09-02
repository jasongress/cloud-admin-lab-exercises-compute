# Solution — Question 4: Attach a Data Disk

Attaching a disk is one command with a small twist: you can create the disk and
attach it in a single step, or create it first and attach it second. Knowing
*why* you'd separate OS data from application data is the real lesson.

---

## Step 1 — Read the requirement into constraints

| Keyword in the problem | Constraint |
|------------------------|------------|
| dedicated disk, separate from OS | a **data** disk (not the OS disk) |
| managed | a **managed** disk (Azure handles the storage account) |
| 32 GiB | `--size-gb 32` |
| named `dev-tool-data` | `--name dev-tool-data` |

**Why a separate data disk?** The OS disk should stay small and disposable — you
might rebuild the VM. Data that must survive a rebuild (a database, uploads,
logs) belongs on its own disk you can detach and re-attach, snapshot, or resize
independently. This separation is a core operational habit.

---

## Step 2 — Find the command

You're acting on a VM's disks, so the noun/verb guess is `az vm disk`:

```bash
az vm disk --help
```

You'll find **`az vm disk attach`**. Read its `--help` and two flags stand out:

- `--new` — create a brand-new disk instead of attaching an existing one.
- `--size-gb` — the size, used together with `--new`.

Reference: <https://learn.microsoft.com/cli/azure/vm/disk#az-vm-disk-attach>

---

## Step 3 — Do it (create + attach in one step)

```bash
az vm disk attach \
  --resource-group lab-compute-vm04-rg \
  --vm-name        dev-tool-vm \
  --name           dev-tool-data \
  --new \
  --size-gb        32
```

`--new` tells Azure to provision a fresh managed disk named `dev-tool-data` and
attach it to the VM in one call. (Without `--new`, `--name` must refer to an
existing disk — that's how you'd re-attach a disk you detached earlier.)

### The two-step way (worth recognizing)

Sometimes you create the disk first — e.g. to set its SKU or zone — then attach:

```bash
az disk create -g lab-compute-vm04-rg -n dev-tool-data --size-gb 32 --sku Premium_LRS
az vm disk attach -g lab-compute-vm04-rg --vm-name dev-tool-vm --name dev-tool-data
```

Same result; more control. Choosing the one-liner vs. the two-step is exactly the
kind of judgment call the docs let you make once you know both exist.

---

## Step 4 — Verify (the cloud-admin part)

```bash
# The disk appears in the VM's data-disk list (name + LUN):
az vm show -g lab-compute-vm04-rg -n dev-tool-vm \
  --query "storageProfile.dataDisks[].{name:name, lun:lun}" -o table

# Its SIZE lives on the disk resource, not the VM's entry (that inline field is
# usually blank for managed disks). The property is diskSizeGb OR diskSizeGB
# depending on your CLI version — this handles both:
az disk show -g lab-compute-vm04-rg -n dev-tool-data --query "diskSizeGb || diskSizeGB" -o tsv

./validate.bash
```

`lun` (Logical Unit Number) is the slot the disk occupies on the VM — you'll use
it to identify the disk inside the OS. Note the split: the **VM** records *that* a
disk is attached and *where* (LUN); the disk's *size* and other properties live on
the **disk resource** you query with `az disk show`.

---

## Step 5 — The other half: make the OS use it (further reading)

Attaching gives the VM a **raw block device**. Linux still has to partition,
format, and mount it before anything can store data there. This is sysadmin work,
not cloud-admin work, so it's outside what we validate — but here's the shape so
you're not surprised.

**First, find the device — don't assume `/dev/sdc`.** Azure's Linux device names
vary by VM size: the data disk might be `/dev/sdc`, another letter, or an NVMe
device like `/dev/nvme0n2`. Guessing a name that doesn't exist gives
`Error: Could not stat device /dev/sdc - No such file or directory`. So list them:

```bash
# (SSH into the VM first)
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS    # find the ~32G disk of TYPE 'disk' with NO mountpoint
```

**The reliable way is Azure's stable LUN symlink** — it points to the right disk
no matter what the kernel calls it. A data disk attached at LUN 0 is always
`/dev/disk/azure/scsi1/lun0`:

```bash
ls -l /dev/disk/azure/scsi1/           # data disks show as lun0, lun1, ...

sudo parted /dev/disk/azure/scsi1/lun0 --script mklabel gpt mkpart primary ext4 0% 100%
sudo mkfs.ext4 /dev/disk/azure/scsi1/lun0-part1
sudo mkdir -p /data
sudo mount /dev/disk/azure/scsi1/lun0-part1 /data
# make it permanent by adding it to /etc/fstab (use the disk's UUID from `blkid`)
```

> If `/dev/disk/azure/scsi1/` doesn't exist on your image, fall back to the device
> name you found with `lsblk` — e.g. `sudo parted /dev/sdX ...` then
> `sudo mkfs.ext4 /dev/sdX1`.

Cloud provisions the hardware; the OS makes it usable. Knowing where that line
sits — and that device names aren't fixed — is part of being a well-rounded admin.

---

## Step 6 — Troubleshooting with composure

| Symptom | Likely cause | Move |
|---------|--------------|------|
| `already exists` on `--new` | A disk named `dev-tool-data` already exists | Drop `--new` to attach the existing one, or pick a new name |
| `Could not stat device /dev/sdc - No such file or directory` | `/dev/sdc` was just an example — your disk has a different name (Azure device naming varies; may be NVMe) | Find the real device with `lsblk`, or use the stable `/dev/disk/azure/scsi1/lun0` path (Step 5) |
| Disk attached but not visible in the OS | You haven't partitioned/mounted it yet | Do Step 5 inside the VM |
| Wrong size shows up | `--size-gb` typo, or you attached an existing disk of another size | Detach (`az vm disk detach`), fix, re-attach |

---

## Cheat sheet

| Goal | Command |
|------|---------|
| Create + attach a new data disk | `az vm disk attach -g <rg> --vm-name <vm> --name <disk> --new --size-gb 32` |
| Attach an existing disk | `az vm disk attach -g <rg> --vm-name <vm> --name <disk>` |
| List a VM's data disks | `az vm show -g <rg> -n <vm> --query "storageProfile.dataDisks[].{name:name,lun:lun}" -o table` |
| Check a disk's size | `az disk show -g <rg> -n <disk> --query "diskSizeGb \|\| diskSizeGB" -o tsv` |
| Detach a disk | `az vm disk detach -g <rg> --vm-name <vm> --name <disk>` |
| Create a standalone disk | `az disk create -g <rg> -n <disk> --size-gb 32 --sku Premium_LRS` |

**Takeaway:** separate the disposable (OS) from the durable (data). Attaching the
disk is the cloud-admin move; formatting it is the OS move — and a good admin
knows exactly where that boundary is.
