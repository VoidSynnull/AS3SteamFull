package game.scenes.carrot.freezer
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.game.GameEvent;
	import game.scenes.carrot.CarrotEvents;
	import game.ui.elements.BasicButton;
	import game.ui.popup.Popup;
	import game.util.DisplayPositionUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class SecurityConsole extends Popup
	{
		public function SecurityConsole(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/carrot/freezer/";
			super.darkenBackground = true;
			super.init(container);
			load();
		}

		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["securityConsole.swf","cutters.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("securityConsole.swf", true) as MovieClip;
			
			DisplayPositionUtils.centerWithinDimensions(this.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 706.25, 542.5);
			
			super.loaded();

			_events = shellApi.islandEvents as CarrotEvents;
			
			_lightBulb = super.screen.content.lightBulb;
			_wiresLeft = MovieClip(super.screen.content.wires).numChildren;
			
			var totalWires:uint = _wiresLeft;
			var wire:MovieClip;
			var i:uint = 0;
				
			if (super.shellApi.checkEvent(_events.SECURITY_DISABLED))
			{
				lightBulbOn( false );
				
				for ( i; i < totalWires; i++ )
				{
					wire = MovieClip(super.screen.content.wires).getChildAt(i) as MovieClip;
					wire.gotoAndStop(2);
				}
			}
			else
			{
				lightBulbOn( true );
				
				
				if ( !super.shellApi.checkEvent(GameEvent.GOT_ITEM + _events.CUTTERS))
				{
					for ( i; i < totalWires; i++ )
					{
						wire = MovieClip(super.screen.content.wires).getChildAt(i) as MovieClip;
						wire.gotoAndStop(1);
					}
				}
				else
				{
					// create cutters
					var cuttersClip:MovieClip = super.getAsset("cutters.swf", true) as MovieClip;
					cuttersClip.mouseEnabled = false;
					_cutters = EntityUtils.createMovingEntity( this, cuttersClip, MovieClip(super.screen) );
					EntityUtils.positionByEntity( _cutters, shellApi.inputEntity );
									
					// TODO :: make pliers clickable to start moving, add auto tilt 
					TimelineUtils.convertClip( cuttersClip.content, this, _cutters );
					EntityUtils.followTarget( _cutters, super.shellApi.inputEntity, .08 );
					
					// add listeners to wires
					for ( i; i < totalWires; i++ )
					{
						wire = MovieClip(super.screen.content.wires).getChildAt(i) as MovieClip;
						if (super.shellApi.checkEvent(_events.WIRE_CUT_ + i))
						{
							wire.gotoAndStop(2);
							_wiresLeft--;
						}
						else
						{
							var basicBtn:BasicButton = ButtonCreator.createBasicButton( wire, [ InteractionCreator.OVER, InteractionCreator.OUT, InteractionCreator.CLICK, ], this );
							basicBtn.value = i;
							basicBtn.over.add( onWireOver);
							basicBtn.out.add( onWireOut );
							basicBtn.click.add( Command.create( onWireClick, basicBtn ) );
							wire.gotoAndStop(1);
						}
					}
				}
			}
			
			super.loadCloseButton();
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.shellApi.triggerEvent( _events.SECURITY_OPEN_CLOSE );
			super.close();
		}
		
		private function onWireOver ( e:Event ): void 
		{
			Timeline(_cutters.get( Timeline )).gotoAndPlay("over");
		}
		
		private function onWireOut ( e:Event ): void 
		{
			Timeline(_cutters.get( Timeline )).gotoAndPlay("out");
		}
		
		private function onWireClick ( e:Event, wireButton:BasicButton ): void 
		{
			wireButton.removeSignals();
			var timeline:Timeline = _cutters.get( Timeline );
	
			timeline.gotoAndPlay("close");
			timeline.labelReached.add( Command.create(onLabelHandler, wireButton ) );
		}
		
		private function onLabelHandler ( label:String, wireButton:BasicButton ): void 
		{
			if ( label == "snip" )
			{
				Timeline(_cutters.get( Timeline )).labelReached.removeAll();
				cutWire( wireButton );
			}
		}
		
		private function cutWire ( wireButton:BasicButton ): void 
		{
			MovieClip(wireButton.displayObject).gotoAndStop(2);
			_wiresLeft--;
			super.shellApi.triggerEvent( _events.WIRE_CUT_ + wireButton.value, true );
			if ( _wiresLeft == 0 )
			{
				lightBulbOn( false );
				super.shellApi.triggerEvent( _events.SECURITY_DISABLED, true );
				SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, onWaitToClose ) );
			}
		}
		
		private function lightBulbOn( bool:Boolean ): void 
		{
			if ( bool )
			{
				_lightBulb.gotoAndStop(1);
			}
			else
			{
				_lightBulb.gotoAndStop(2);
			}
		}
		
		public function onWaitToClose():void 
		{
			this.close();
		}
		
		private var _wiresLeft:int;
		private var _cutters:Entity;
		private var _lightBulb:MovieClip
		private var _events:CarrotEvents;
	}
}
