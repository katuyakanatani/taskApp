import UIKit
import RealmSwift //追加
import UserNotifications
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchBar: UISearchBar!
  //検索のやつ
  var searchResult = [String]()
  //Realmインスタンスを取得する
  let realm = try! Realm() //追加
  //DB内のタスクが格納されるリスト
  //日付の近い順でソート：昇順
  //以降内容をアップデートするとすると内は自動的に更新される。
  var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true) //追加
   
   
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    tableView.delegate = self
    tableView.dataSource = self
    searchBar.delegate = self
    searchBar.enablesReturnKeyAutomatically = false
  }
   
  //データの数w（＝セルの数）を返すメソッド
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return taskArray.count
  }
//各セル内容を返すメソッド
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //再利用可能なCellを得る
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    //Cellに値を設定
    let task = taskArray[indexPath.row]
    cell.textLabel?.text = "\(task.title) [\(task.category)]"
     
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    
    return cell
  }
  //各セルを選択した時に実行されるメソッド
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
    performSegue(withIdentifier: "cellSegue",sender: nil) //←追加する
  }
  //セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .delete
  }
  //検索ボタンおされた時
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    if searchBar.text == "" {
        taskArray = try! Realm().objects(Task.self)
        tableView.reloadData()
    } else {
        taskArray = try! Realm().objects(Task.self).filter("category == %@", searchBar.text!)
        tableView.reloadData()
        }
      }
    
  // Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    //追加
    if editingStyle == .delete {
      //削除するタスクを取得する
      let task = self.taskArray[indexPath.row]
      //ローカル通知をキャンセルする
      let center = UNUserNotificationCenter.current()
      center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
      //データベースから削除する
      try! realm.write {
        self.realm.delete(task)
        tableView.deleteRows(at: [indexPath], with: .fade)
      }
      //未通知のローカル通知一覧をログ出力
      center.getPendingNotificationRequests { (request: [UNNotificationRequest]) in
        for request in request {
          print("/--------")
          print(request)
          print("--------/")
        }
      }
    }
  }
  override func prepare(for segue: UIStoryboardSegue, sender: Any?){
    let inputViewController:InputViewController = segue.destination as! InputViewController
    if segue.identifier == "cellSegue" {
      let indexPath = self.tableView.indexPathForSelectedRow
      inputViewController.task = taskArray[indexPath!.row]
    } else {
      let task = Task()
      let allTasks = realm.objects(Task.self)
      if allTasks.count != 0 {
        task.id = allTasks.max(ofProperty: "id")! + 1
      }
      inputViewController.task = task
    }
     
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
     
  }
}
