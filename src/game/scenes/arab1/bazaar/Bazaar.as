package game.scenes.arab1.bazaar
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.hit.CurrentHit;
	import game.components.scene.SceneInteraction;
	import game.data.character.LookData;
	import game.data.scene.hit.HitData;
	import game.scenes.arab1.bazaar.tradePopup.TradePopup;
	import game.scenes.arab1.desertScope.DesertScope;
	import game.scenes.arab1.shared.Arab1Scene;
	import game.scenes.arab1.shared.creators.CamelCreator;
	import game.systems.entity.character.states.CharacterState;
	import game.ui.elements.DialogPicturePopup;
	import game.util.CharUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class Bazaar extends Arab1Scene
	{
		public function Bazaar()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab1/bazaar/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			if(!shellApi.checkEvent(arab.INTRO_COMPLETE))
				SceneUtil.removeIslandParts(this);
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			//addChildGroup(new CardGame(overlayContainer));
			
			setUpTelescope();
			setUpCamel();
			setUpInteractions();
			setUpIntro();
		}
		
		private function setUpInteractions():void
		{
			if(PlatformUtils.isMobileOS)
			{
				removeEntity(getEntityById("door_common"));
			}
			var interactions:Vector.<String> = new Vector.<String>();
			interactions.push(arab.LAMP, arab.SPY_GLASS);
			var interaction:Interaction;
			var interactionName:String
			var entity:Entity;
			for(var i:int = 0; i < interactions.length; i++)
			{
				interactionName = interactions[i];
				entity = getEntityById(interactionName+"Interaction");
				entity.remove(SceneInteraction);
				Display(entity.get(Display)).alpha = 0;
				interaction = entity.get(Interaction);
				interaction.click.add(Command.create(comment, i+1));
			}
		}
		
		private function comment(entity:Entity, number:int):void
		{
			Dialog(getEntityById(TRADER+number).get(Dialog)).sayById("comment");
		}
		
		private function setUpIntro():void
		{
			if(!shellApi.checkEvent(arab.INTRO_COMPLETE))
			{
				shellApi.completeEvent(arab.INTRO_COMPLETE);
				showIntroPopup();
			}
		}
		
		private function showIntroPopup():void
		{
			var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			introPopup.updateText("The 40 thieves are ransacking the town. Find their hideout and put a stop to it!", "Start");
			introPopup.configData("introPopup.swf", "scenes/arab1/shared/popups/");
			addChildGroup(introPopup);
		}
		
		private function setUpCamel():void
		{
			if(!shellApi.checkEvent(CamelCreator.PLAYER_HOLDING_CAMEL) && !shellApi.checkEvent(arab.CAMEL_ON_DIAS) && !shellApi.checkEvent(arab.CAMEL_TAKEN))
				camelCreator.create(new Point(1400, this.sceneData.bounds.bottom - 100), getEntityById("trader3"),300, camelCreated);
		}
		
		private function camelCreated(camel:Entity):void
		{
			var interaction:Interaction = InteractionCreator.addToEntity(camel, ["click"]);
			interaction.click.add(Command.create(comment, 3));
		}
		
		private function setUpTelescope():void
		{
			telescope = getEntityById("telescopeInteraction");
			var interaction:SceneInteraction = telescope.get(SceneInteraction);
			interaction.reached.add(lookInTelescope);
			interaction.validCharStates = new <String>[CharacterState.STAND];
			showSpyGlass(shellApi.checkEvent(arab.PLACED_TELESCOPE));
			
			if(onMinaret())
			{
				if(shellApi.checkEvent(arab.SMOKE_BOMB_LEFT) && !shellApi.checkHasItem(arab.SMOKE_BOMB))
				{
					Dialog(player.get(Dialog)).sayById(arab.SMOKE_BOMB_LEFT);
				}
				else if(shellApi.checkEvent(arab.CAMEL_TAKEN))
				{
					Dialog(player.get(Dialog)).sayById(arab.CAMEL_TAKEN);
				}
			}
		}
		
		private function showSpyGlass(show:Boolean = false):void
		{
			if(show)
				Display(telescope.get(Display)).alpha = 1;
			else
				Display(telescope.get(Display)).alpha = 0;
		}
		
		private function lookInTelescope(...args):void
		{
			if(shellApi.checkEvent(arab.PLACED_TELESCOPE))
				shellApi.loadScene(DesertScope);
			else
				Dialog(player.get(Dialog)).sayById("need_spy_glass");
		}
		
		private const TRADER:String = "trader";
		private var telescope:Entity;
		
		private function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "hasItem_"	+ arab.CAMEL_HARNESS)
			{
				getHarness();
			}
			
			if(event.indexOf(TRADER) == 0)
			{
				var traderNumber:uint = uint(event.substring(TRADER.length));
				openPopup(traderNumber);
			}
			
			if(event == arab.SPY_GLASS)
			{
				useSpyGlass();
			}
			
			if(event == arab.CAMEL_HARNESS)
			{
				useCamelHarnes();
			}
		}
		
		private function getHarness():void
		{
			Dialog(getEntityById(TRADER+3).get(Dialog)).sayById("gave_camel_harness");
		}
		
		override public function useCamelHarnes(...args):void
		{
			if(getEntityById("camel1") == null)
			{
				super.useCamelHarnes();
				return;
			}
			gotoCamelTrader();
		}
		
		private function gotoCamelTrader():void
		{
			var spatial:Spatial = getEntityById("trader3").get(Spatial);
			CharUtils.moveToTarget(player, spatial.x, spatial.y, false, pickUpReturnCamel);
		}
		
		private function pickUpReturnCamel(entity:Entity):void
		{
			if(shellApi.checkEvent(CamelCreator.PLAYER_HOLDING_CAMEL))
				camelCreator.setCamelsHandler(getEntityById("camel1"),getEntityById("trader3"));
			else
				camelCreator.setCamelsHandler(getEntityById("camel1"), player);
		}
		
		private function openPopup(traderNumber:uint):void
		{
			var trader:Entity = getEntityById(TRADER + traderNumber);
			var look:LookData = SkinUtils.getLook(trader);
			addChildGroup(new TradePopup(overlayContainer, traderNumber, look));
		}
		
		override public function useSpyGlass(...args):void
		{
			if(onMinaret())
			{
				if(!shellApi.checkEvent(arab.PLACED_TELESCOPE))
				{
					showSpyGlass(true);
					shellApi.completeEvent(arab.PLACED_TELESCOPE);
				}
				shellApi.removeItem(arab.SPY_GLASS);
			}
			else
			{
				super.useSpyGlass();
			}
		}
		
		private function onMinaret():Boolean
		{
			var hit:Entity = CurrentHit(player.get(CurrentHit)).hit;
			if(hit != null)
			{
				if(HitData(hit.get(HitData)).id == "minaret")
				{
					return true;
				}
			}
			return false;
		}
	}
}