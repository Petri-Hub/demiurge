DEMIURGE_AGENT=Demiurge.md

is_demiurge_skill() {
  case "$1" in
    forge-*|pipeline-demiurge-*|workspace-structural-protocol|workspace-lifecycle-protocol|workspace-evolution-protocol) return 0 ;;
    *) return 1 ;;
  esac
}
