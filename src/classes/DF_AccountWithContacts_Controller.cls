/*
*   @Class : DF_AccountWithContacts_Controller
*
*   @Author             :   Gonzalo Abruna & Mary Scotton
*   @Created            :   29 September 2014
*   @Description        :   Class that will calculate the three newest Contacts per each Account.
*
*   Modification Log
*   ----------------------------------------------------------------------------------------------------------------------------
*   #       Developer               Date                    Description
*   ----------------------------------------------------------------------------------------------------------------------------    
*   1       Gonzalo Abruna          29 Sep 2014             Creation
*/
public with sharing class DF_AccountWithContacts_Controller {
    /*
     * @Method          :   executeSolution1
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   29 Sep 2014
     * @Description     :   First solution to calculate the latest 3 contacts of each account
     * @Params          :   -
     * @Returns         :   -
     * @MaxSoqls        :   2
     * @MaxDmls         :   0
     */
	public void executeSolution1(){
		final Integer MAX_CONTACTS = 3;
		Map<Id, List<Contact>> mapContactsPerAccount = new map<Id, List<Contact>>();

		//Query all the Accounts
		Map<Id, Account> mapAccounts = new Map<Id, Account>([SELECT Id, Name FROM Account]);

		//Query all the Contacts per each one of those Accounts
		List<Contact> listContacts = [SELECT Id, Name, AccountId, CreatedDate FROM Contact WHERE AccountId in :mapAccounts.keySet() ORDER BY CreatedDate DESC];
		for(Contact c : listContacts){
			if(!mapContactsPerAccount.containsKey(c.AccountId))
				mapContactsPerAccount.put(c.AccountId, new List<Contact>());
			if(mapContactsPerAccount.get(c.AccountId).size() < MAX_CONTACTS)
				mapContactsPerAccount.get(c.AccountId).add(c);
		}

	}

    /*
     * @Method          :   executeSolution2
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   29 Sep 2014
     * @Description     :   Second solution to calculate the latest 3 contacts of each account
     * @Params          :   -
     * @Returns         :   -
     * @MaxSoqls        :   1
     * @MaxDmls         :   0
     */
	public void executeSolution2(){
		final Integer MAX_CONTACTS = 3;
		Map<Id, List<Contact>> mapContactsPerAccount = new map<Id, List<Contact>>();

		//Query all the Accounts with their related contacts
		Map<Id, Account> mapAccounts = new Map<Id, Account>([SELECT Id, Name, (SELECT Id, Name, CreatedDate FROM Contacts ORDER BY CreatedDate DESC LIMIT 3) 
																FROM Account]);

		for(Account a : mapAccounts.values()){
			if(a.Contacts != null){
				mapContactsPerAccount.put(a.Id, a.Contacts);
			}
		}
	}
}