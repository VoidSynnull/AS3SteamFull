package game.scenes.arab1.shared
{
	import game.components.entity.Dialog;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab1.Arab1Events;
	import game.scenes.arab1.shared.creators.CamelCreator;
	
	public class Arab1Scene extends PlatformerGameScene
	{
		public var camelCreator:CamelCreator;
		public var arab:Arab1Events;
		
		public function Arab1Scene()
		{
			super();
		}
		
		override public function loaded():void
		{
			super.loaded();
			arab = events as Arab1Events;
			camelCreator = new CamelCreator(this, _hitContainer);
			if(shellApi.checkEvent(CamelCreator.PLAYER_HOLDING_CAMEL))
			{
				camelCreator.create(null, player);
			}
			
			shellApi.eventTriggered.add(onEventTriggered);
		}
		
		protected function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == arab.CAMEL_HARNESS)
			{
				useCamelHarnes();
			}
			
			if(event == arab.SALT)
			{
				useSalt();
			}
			
			if(event == arab.CLOTH)
			{
				useCloth();
			}
			
			if(event == arab.GRAIN)
			{
				useGrain();
			}
			
			if(event == arab.LAMP)
			{
				useLamp();
			}
			
			if(event == arab.SPY_GLASS)
			{
				useSpyGlass();
			}
			
			if(event == arab.CROWN_JEWEL)
			{
				useCrownJewel();
			}
			
			if(event == arab.PEARL)
			{
				usePearl();
			}
			
			if(event == arab.IVORY_CAMEL)
			{
				useIvoryCamel();
			}
		}
		
		public function useSalt(...args):void
		{
			Dialog(player.get(Dialog)).sayById("no_use_salt");
		}
		
		public function useCamelHarnes(...args):void
		{
			Dialog(player.get(Dialog)).sayById("no_use_camel_harness");
		}
		
		public function useCloth(...args):void
		{
			Dialog(player.get(Dialog)).sayById("no_use_cloth");
		}
		
		public function useGrain(...args):void
		{
			Dialog(player.get(Dialog)).sayById("no_use_grain");
		}
		
		public function useLamp(...args):void
		{
			Dialog(player.get(Dialog)).sayById("no_use_lamp");
		}
		
		public function useSpyGlass(...args):void
		{
			Dialog(player.get(Dialog)).sayById("no_use_spy_glass");
		}
		
		public function useCrownJewel(...args):void
		{
			Dialog(player.get(Dialog)).sayById("no_use_crown_jewel");
		}
		
		public function usePearl(...args):void
		{
			Dialog(player.get(Dialog)).sayById("no_use_pearl");
		}
		
		public function useIvoryCamel(...args):void
		{
			Dialog(player.get(Dialog)).sayById("no_use_ivory_camel");
		}
	}
}