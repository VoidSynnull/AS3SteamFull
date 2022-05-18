package com.poptropica.shells.browser.steps
{
	import game.proxy.PopDataStoreRequest;

	public class BrowserStepGetMemberStatus extends ShellStep
	{
		// gets status of user membership
		public function BrowserStepGetMemberStatus()
		{
			super();
			stepDescription = "Getting membership status";
		}
		
		override protected function build():void
		{
			shellApi.siteProxy.retrieve(PopDataStoreRequest.memberStatusRequest());
			built();
		}
	}
}