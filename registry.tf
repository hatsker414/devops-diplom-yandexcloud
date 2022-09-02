resource "yandex_container_registry" "diplom" {
  name      = "devops-9"
  folder_id = "b1glh44698ke0dcg2atn"

  labels = {
    my-label = "diplom-app"
  }
}
