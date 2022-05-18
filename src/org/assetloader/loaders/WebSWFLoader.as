package org.assetloader.loaders
{
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	
	import org.assetloader.base.AssetType;
	import org.assetloader.base.Param;

	/**
	 * <code>WebSWFLoader</code> is just like <code>SWFLoader</code>,
	 * but it adds an additional parameter: <code>Param.LOADER_CONTEXT</code>
	 * which alleviates Security Sandbox Violations when assets
	 * are stored on Akamai (which is a different domain).
	 * 
	 * @author Rich Martin
	 * 
	 * @see flash.system.LoaderContext
	 */
	public class WebSWFLoader extends SWFLoader
	{

		public function WebSWFLoader(request : URLRequest, id : String = null)
		{
			super(request, id);
			_type = AssetType.SWF;
			addParam(new Param(Param.LOADER_CONTEXT, new LoaderContext(false, null, SecurityDomain.currentDomain)));
		}

	}
}
