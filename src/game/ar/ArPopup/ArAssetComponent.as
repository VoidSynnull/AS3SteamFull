package game.ar.ArPopup
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	
	public class ArAssetComponent extends Component
	{
		public var asset:ArAsset;
		public var emoteStates:Dictionary = new Dictionary();
		public var lastEmote:String;
		//public var face:BRFFace;
		public function ArAssetComponent(asset:ArAsset, face:String)
		{
			this.asset = asset;
			//this.face = face;
			
			if(asset.emotes.indexOf(ArEffectSysytem.DEFAULT) == -1)
				asset.emotes.push(ArEffectSysytem.DEFAULT);
			
			for(var i:int = 0; i < asset.emotes.length; i++)
			{
				emoteStates[asset.emotes[i]] = false;
			}
		}
	}
}