package com.poptropica.shells.shared.steps
{
	import com.poptropica.shellSteps.shared.CreateConnection;
	
	import game.proxy.DataStoreProxyPop;
	
	public class CreateConnectionPop extends CreateConnection
	{
		public function CreateConnectionPop()
		{
			super();
			super.dataStoreClass = DataStoreProxyPop;
		}
	}
}