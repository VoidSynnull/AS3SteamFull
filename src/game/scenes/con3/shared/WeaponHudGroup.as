package game.scenes.con3.shared
{	
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.game.GameEvent;
	import game.data.ui.ToolTipType;
	import game.scenes.con3.Con3Events;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class WeaponHudGroup extends Group
	{
		private var _events:Con3Events;
		
		private const WORLD_GUY:String				=	"poptropicon_worldguy";
		private const SILVER_AGE_WORLD_GUY:String	=	"poptropicon_saworldguy";
		private const GOLD_FACE_FRONT:String		=	"poptropicon_goldface_front";
		
		public function WeaponHudGroup( shellApi:ShellApi )
		{
			this.shellApi = shellApi;	
			
			_events = shellApi.islandEvents as Con3Events;
			shellApi.eventTriggered.add( this.eventTriggered );
			super.shellApi.loadFile( super.shellApi.assetPrefix + "scenes/con3/shared/weapons_gui.swf", setupWeaponsGUI );
		}
		
		public function setupWeaponsGUI( asset:MovieClip ):void
		{
			var button:Button;
			var clip:MovieClip;
			var child:Entity;
			var display:Display;
			var id:Id;
			var interaction:Interaction;
			var sleep:Sleep;
			var timeline:Timeline;
			var weapon:Entity;
			var weapons:Vector.<MovieClip> = new <MovieClip>[ asset.getChildByName( _events.BOW ) as MovieClip
															, asset.getChildByName( _events.GAUNTLETS ) as MovieClip
															, asset.getChildByName( _events.SHIELD ) as MovieClip ];
			
			for each( clip in weapons )
			{
				shellApi.currentScene.overlayContainer.addChildAt(clip, 0);
				clip.y = shellApi.viewportHeight - clip.height / 2;
				weapon = ButtonCreator.createButtonEntity( clip, this.parent, useWeapon );			
				ToolTipCreator.removeFromEntity( weapon );
				
				button = weapon.get( Button );
				
				interaction = weapon.get( Interaction );
				interaction.releaseOutside = new Signal();
				interaction.releaseOutside.add( button[ "upHandler"]);
				
				display = weapon.get( Display );
				id = weapon.get( Id );
				id.id = clip.name + "Button";
				
				button.isSelected = false;
				
				if( clip.name == _events.BOW)
				{
					if(SkinUtils.hasSkinValue( shellApi.player, SkinUtils.ITEM, _events.BOW ))
					{
						button.isSelected = true;
					}
					else if(!shellApi.checkHasItem( clip.name ))
					{
						toggleWeapon( clip.name, false );
					}
				}
				else if( clip.name == _events.SHIELD )
				{
					child = TimelineUtils.convertClip( display.displayObject.getChildByName( "asset" ), this.parent, null, weapon, false );
					child.add( new Id( "shieldAsset" ));
					
					timeline = child.get( Timeline );
					
					if( SkinUtils.hasSkinValue( shellApi.player, SkinUtils.ITEM, WORLD_GUY ) || SkinUtils.hasSkinValue( shellApi.player, SkinUtils.ITEM, SILVER_AGE_WORLD_GUY ))
					{
						button.isSelected = true;	
					}
					if( shellApi.checkHasItem( _events.SHIELD ))
					{
						timeline.gotoAndStop( "current" );
					}
					else if(!shellApi.checkHasItem( _events.OLD_SHIELD ))
					{
						toggleWeapon( _events.SHIELD, false );
					}
				}
				else if( clip.name == _events.GAUNTLETS)
				{
					if(SkinUtils.hasSkinValue( shellApi.player, SkinUtils.ITEM, GOLD_FACE_FRONT ))
					{
						button.isSelected = true;
					}
					else if(!shellApi.checkHasItem( clip.name ))
					{
						toggleWeapon( clip.name, false );
					}
				}
			}
			
			this.groupReady();
		}
		
		private function toggleWeapon( weaponName:String, activate:Boolean = true ):void
		{
			var weapon:Entity = this.parent.getEntityById( weaponName + "Button" );
			var display:Display = weapon.get( Display );
			var sleep:Sleep = weapon.get( Sleep );
			
			var child:Entity = this.parent.getEntityById( "shieldAsset" );
			
			if( activate )
			{
				display.visible = true;
				sleep.sleeping = false;
				
				if( weaponName == _events.SHIELD )
				{
					var timeline:Timeline = child.get( Timeline );
					
					if( shellApi.checkEvent( GameEvent.HAS_ITEM + _events.SHIELD ))
					{
						timeline.gotoAndStop( 1 );
					}
					else
					{
						timeline.gotoAndStop( 0 );
					}
				}
			}
			else
			{
				display.visible = false
				sleep.sleeping = true;
			}
		}
		
		private function useWeapon( weapon:Entity ):void
		{
			var display:Display = weapon.get( Display );
			var button:Button;
			var id:Id = weapon.get( Id );
			var value:String = id.id.substr( 0, id.id.length - 6 );
			
			if( value == _events.GAUNTLETS )
			{
				value = GOLD_FACE_FRONT;
				
				button = this.parent.getEntityById( _events.BOW + "Button" ).get( Button );
				button.isSelected = false;
				
				button = this.parent.getEntityById( _events.SHIELD + "Button" ).get( Button );
				button.isSelected = false;
			}
			
			if( value == _events.SHIELD )
			{
				if( shellApi.checkHasItem( _events.SHIELD ))
				{
					value = WORLD_GUY;
				}
				else
				{
					value = SILVER_AGE_WORLD_GUY;
				}
				
				button = this.parent.getEntityById( _events.BOW + "Button" ).get( Button );
				button.isSelected = false;
				
				button = this.parent.getEntityById( _events.GAUNTLETS + "Button" ).get( Button );
				button.isSelected = false;
			}
			
			if( value == _events.BOW )
			{
				button = this.parent.getEntityById( _events.GAUNTLETS + "Button" ).get( Button );
				button.isSelected = false;	
				
				button = this.parent.getEntityById( _events.SHIELD + "Button" ).get( Button );
				button.isSelected = false;
			}
			
			button = weapon.get( Button );
			if( !SkinUtils.hasSkinValue( shellApi.player, SkinUtils.ITEM, value ))
			{
				SkinUtils.setSkinPart( shellApi.player, SkinUtils.ITEM, value, true );//, Command.create( setButtonState ));
				button.isSelected = true;
			}
			else
			{
				SkinUtils.emptySkinPart( shellApi.player, SkinUtils.ITEM, true );
				button.isSelected = false;
			}
		}
		
		protected function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var toggle:Boolean;
			
			// TOGGLES THE WEAPON GUI OFF IF YOU LOST THE ITEM
			if( event == GameEvent.GOT_ITEM + _events.BOW )
			{
				toggle = shellApi.checkEvent( GameEvent.HAS_ITEM + _events.BOW );
				toggleWeapon( _events.BOW, toggle );
			}
			if( event == GameEvent.GOT_ITEM + _events.GAUNTLETS )
			{
				toggle = shellApi.checkEvent( GameEvent.HAS_ITEM + _events.GAUNTLETS );
				toggleWeapon( _events.GAUNTLETS, toggle );			
			}
			if( event == GameEvent.GOT_ITEM + _events.OLD_SHIELD || event == GameEvent.GOT_ITEM + _events.SHIELD )
			{
				toggle = ( shellApi.checkEvent( GameEvent.HAS_ITEM + _events.OLD_SHIELD ) || shellApi.checkEvent( GameEvent.HAS_ITEM + _events.OLD_SHIELD ));
				toggleWeapon( _events.SHIELD, toggle );				
			}

			// TOGGLES THE WEAPON GUI ON IF YOU HAVE THE ITEM
			if( event == GameEvent.HAS_ITEM + _events.SHIELD || event == GameEvent.HAS_ITEM + _events.OLD_SHIELD )
			{
				toggleWeapon( _events.SHIELD );
			}
			if( event == GameEvent.HAS_ITEM + _events.BOW )
			{
				toggleWeapon( _events.BOW );
			}
			if( event == GameEvent.HAS_ITEM + _events.GAUNTLETS )
			{
				toggleWeapon( _events.GAUNTLETS );
			}
		}
	}
}