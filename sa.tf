resource "yandex_iam_service_account" "k8s" {   
  folder_id = "b1glh44698ke0dcg2atn"
  name  = "k8s"                                                                           
}                                                       
                                                                                  
resource "yandex_iam_service_account" "pusher" {   
  folder_id = "b1glh44698ke0dcg2atn"
  name  = "pusher"                                                                           
}                                                                             
                                                                                  
// Grant permissions                                                                            
resource "yandex_resourcemanager_folder_iam_member" "k8s-editor" {                                                              
  folder_id = "b1glh44698ke0dcg2atn"                                                                          
  role  = "editor"                                                                            
  member  = "serviceAccount:${yandex_iam_service_account.k8s.id}"                                                             
}          
                                                     
               
resource "yandex_container_registry_iam_binding" "pusher" {
  registry_id = "${yandex_container_registry.diplom.id}"
  role        = "editor"
  members = ["serviceAccount:${yandex_iam_service_account.pusher.id}"]
}
