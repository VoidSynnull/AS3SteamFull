package game.proxy
{
	public interface IDataStore2 extends IDataStore
	{
		function call(transactionData:DataStoreRequest, callback:Function=null):int;
	}
}