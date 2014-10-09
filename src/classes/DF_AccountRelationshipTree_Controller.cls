/*
*   @Class : DF_AccountRelationshipTree_Controller
*
*   @Author             :   Gonzalo Abruna & Mary Scotton
*   @Created            :   14 September 2014
*   @Description        :   Class that will calculate the tree of Accounts-Contacts(SubAccount)-Accounts(SubAccount).
*							Per each Account will get the list of Contacts linked via SubAccount Relationship custom object,
*							and per each one of those Contact will calculate the list of Accounts linked via SubAccount Relationship.
*
*   Modification Log
*   ----------------------------------------------------------------------------------------------------------------------------
*   #       Developer               Date                    Description
*   ----------------------------------------------------------------------------------------------------------------------------    
*   1       Gonzalo Abruna          14 Sep 2014             Creation
*/
public with sharing class DF_AccountRelationshipTree_Controller {
	public Map<Id, List<SubAccount_Relationship__c>> subContactsOfAccountId{get;set;}
	public Map<Id, List<SubAccount_Relationship__c>> subAccountsOfContactId{get;set;}
	public Map<Id, String> mapAccountNames{get;set;}
	public Map<Id, String> mapContactNames{get;set;}
	public Integer cpuTime{get;set;}

    /*
     * @Method          :   DF_AccountRelationshipTree_Controller
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   14 Sep 2014
     * @Description     :   Constructor method of the class
     * @Params          :   -
     * @Returns         :   -
     * @MaxSoqls        :   0
     * @MaxDmls         :   0
     */
	public DF_AccountRelationshipTree_Controller() {
		resetValues();
	}

    /*
     * @Method          :   resetValues
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   15 Sep 2014
     * @Description     :   Sets main values back to default
     * @Params          :   -
     * @Returns         :   -
     * @MaxSoqls        :   0
     * @MaxDmls         :   0
     */
	private void resetValues(){
		cpuTime = 0;
	}

    /*
     * @Method          :   executeQuerySolution1
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   14 Sep 2014
     * @Description     :   First option to solve the algorithm
     * @Params          :   -
     * @Returns         :   -
     * @MaxSoqls        :   3
     * @MaxDmls         :   0
     */
	public void executeQuerySolution1(){
		resetValues();
		//1. Get all the accounts
		List<Account> listAccounts = [SELECT Id, Name FROM Account];

		//2. Get all the SubAccount Relationship for these listAccounts
		Set<Id> setAccountIds = new Set<Id>();
		for(Account a : listAccounts){
			setAccountIds.add(a.Id);
		}
		List<SubAccount_Relationship__c> listSubAccounts = [SELECT Id, Account__c, Contact__c, Contact__r.Name 
															FROM SubAccount_Relationship__c WHERE Account__c IN :setAccountIds];

		//3. Get all the Contacts for those Accounts (via SubAccount_Relationship__c)
		Set<Id> setSubContactIds = new Set<Id>();
		for(SubAccount_Relationship__c s : listSubAccounts){
			setSubContactIds.add(s.Contact__c);
		}

		//4. Get all the Accounts for those Contacts (via SubAccount_Relationship__c)
		List<SubAccount_Relationship__c> listAccountsOfContacts = [SELECT Id, Account__c, Contact__c, Contact__r.Name 
																	FROM SubAccount_Relationship__c 
																	WHERE Contact__c IN :setSubContactIds];
		calculateCpuTime();
	}

    /*
     * @Method          :   executeQuerySolution2
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   14 Sep 2014
     * @Description     :   Second option to solve the algorithm
     * @Params          :   -
     * @Returns         :   -
     * @MaxSoqls        :   2
     * @MaxDmls         :   0
     */
	public void executeQuerySolution2(){
		resetValues();
		//1. Get all the Accounts with their SubAccount relationships, directly from the subaccount
		List<SubAccount_Relationship__c> listSubAccounts = [SELECT Id, Account__c, Account__r.Name, Contact__c FROM SubAccount_Relationship__c];

		if(listSubAccounts.isEmpty()){
			calculateCpuTime();
			return;
		}

		//2. Per each subAccount, get all the contacts
		Set<Id> setContactIds = new Set<Id>();
		for(SubAccount_Relationship__c s : listSubAccounts){
			setContactIds.add(s.Contact__c);
		}
		Map<Id, Contact> mapSubAccountsOfContact =  new Map<Id,Contact>([SELECT Id, Name, (SELECT Account__c, Account__r.Name FROM SubAccount_Relationships__r)
																		FROM Contact WHERE Id IN :setContactIds]);
		calculateCpuTime();
	}

    /*
     * @Method          :   executeQuerySolution3
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   14 Sep 2014
     * @Description     :   Third option to solve the algorithm
     * @Params          :   -
     * @Returns         :   -
     * @MaxSoqls        :   1
     * @MaxDmls         :   0
     */
	public void executeQuerySolution3(){
		resetValues();
		//1. Get all the Data in one single query
		List<SubAccount_Relationship__c> listSubRelationships = [SELECT Id, Account__c, Account__r.Name, Contact__c, Contact__r.Name FROM SubAccount_Relationship__c];

		if(listSubRelationships.isEmpty()){
			calculateCpuTime();
			return;
		}
		calculateCpuTime();
	}

    /*
     * @Method          :   calculateSubAccountTree
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   15 Sep 2014
     * @Description     :   Calculates the SubAccount tree: populates the values for subContactsOfAccountId and subAccountsOfContactId
     * @Params          :   -
     * @Returns         :   -
     * @MaxSoqls        :   2
     * @MaxDmls         :   0
     */
    public void calculateSubAccountTree(){
    	//1. Get all the Data in one single query
		List<SubAccount_Relationship__c> listSubRelationships = [SELECT Id, Account__c, Account__r.Name, Contact__c, Contact__r.Name FROM SubAccount_Relationship__c];

		if(listSubRelationships.isEmpty()){
			return;
		}

		//SECOND PART: USING Map<Id, List<sObject>>()
		//Create the Map AccountId, List<SubAccount>:
		mapAccountNames = new Map<Id, String>();
		mapContactNames = new Map<Id, String>();
		subContactsOfAccountId = new Map<Id, List<SubAccount_Relationship__c>>();
		subAccountsOfContactId = new Map<Id, List<SubAccount_Relationship__c>>();
		for(SubAccount_Relationship__c sAcc : listSubRelationships){
			if(!subContactsOfAccountId.containsKey(sAcc.Account__c)){ //Be careful with null pointer exceptions
				subContactsOfAccountId.put(sAcc.Account__c, new List<SubAccount_Relationship__c>());
			}
			subContactsOfAccountId.get(sAcc.Account__c).add(sAcc);
			mapAccountNames.put(sAcc.Account__c, sAcc.Account__r.Name);

			//Reuse this loop to get the subAccounts of the Contacts for this Account sAcc
			if(!subAccountsOfContactId.containsKey(sAcc.Contact__c)){ //If this contact has not been added
				subAccountsOfContactId.put(sAcc.Contact__c, new List<SubAccount_Relationship__c>()); //Be careful with null pointer exceptions
				mapContactNames.put(sAcc.Contact__c, sAcc.Contact__r.Name);
			}
			subAccountsOfContactId.get(sAcc.Contact__c).add(sAcc); //Avoids loops
		}
    }

    /*
     * @Method          :   getIsSubAccountEmpty
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   15 Sep 2014
     * @Description     :   Returns if the SubAccount list is empty
     * @Params          :   -
     * @Returns         :   Boolean
     * @MaxSoqls        :   0
     * @MaxDmls         :   0
     */
	public Boolean getIsSubAccountEmpty(){
		return subAccountsOfContactId == null ? true : subAccountsOfContactId.isEmpty();
	}

    /*
     * @Method          :   calculateCpuTime
     * @Author          :   Gonzalo Abruna & Mary Scotton
     * @Created         :   14 Sep 2014
     * @Description     :   Calculates the value of cpuTime
     * @Params          :   -
     * @Returns         :   void
     * @MaxSoqls        :   0
     * @MaxDmls         :   0
     */
	private void calculateCpuTime(){
		cpuTime = Limits.getCpuTime();
	}

}