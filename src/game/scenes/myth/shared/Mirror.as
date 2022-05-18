package game.scenes.myth.shared
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.group.TransportGroup;
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.CharacterDialogGroup;
	import game.scenes.myth.MythEvents;
	import game.scenes.myth.cerberus.Cerberus;
	import game.scenes.myth.mainStreet.MainStreet;
	import game.scenes.myth.poseidonBeach.PoseidonBeach;
	import game.scenes.myth.poseidonWater.PoseidonWater;
	import game.ui.popup.Popup;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	
	public class Mirror extends Popup
	{
		public function Mirror( container:DisplayObjectContainer=null, withHerc:Boolean = false )
		{
			_withHerc = withHerc;
			super( container );
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/myth/shared/";
			super.screenAsset = "mirror.swf";
			super.init( container );
			this.load();
		}		
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			this.letterbox(this.screen.content, new Rectangle(0, 0, 500, 600), false);
			
			loadCloseButton();
			
			characterDialogGroup = parent.getGroupById( "characterDialogGroup" ) as CharacterDialogGroup;
			
			var textField:TextField;
			var data:DialogData
			var textFormat:TextFormat = new TextFormat( "CreativeBlock BB", 16, 0x000000, false, false, false, null, null, "left", null, 0, null, 5 );
			
			data = characterDialogGroup.allDialogData[ "mirror" ][ "description" ];
			textField = TextUtils.refreshText( super.screen.content.description );
			textField.embedFonts = true;
			textField.wordWrap = true;
			
			textField.defaultTextFormat = textFormat;
			textField.text = data.dialog;
			
			var mirror:DisplayObject = this.screen.content.mirror;
			var bounds:Rectangle = mirror.getBounds(mirror.parent);
			bounds.inflate(48, 48); //Accounting for filter.
			this.createBitmap(mirror, 1.5, bounds);
			this.createBitmap(this.screen.content.textBox);
			
			setupPortals();
		
			_events = super.shellApi.islandEvents as MythEvents;			
		}
		
		private function setupPortals():void
		{	
			var button:Entity;
			var interaction:Interaction;
			var clip:MovieClip;
			
			var destination:Class;
			var posX:Number;
			var posY:Number;
			
			for( var number:int = 1; number < 5; number ++ )
			{
				// Create buttons for each scene portal				
				clip = MovieClip( MovieClip( super.screen.content ).getChildByName( "screen" + number ));
				button = ButtonCreator.createButtonEntity( clip, this, null, null, [InteractionCreator.CLICK, InteractionCreator.OVER], null, true );
				interaction = button.get( Interaction );
				button.add( new Id( "scene" + number ));
			
				switch( number )
				{
					case 1:
						destination = MainStreet;
						posX = 2950;
						posY = 1110;
						break;
					case 2:
						destination = Cerberus;
						posX = 1760;
						posY = 550;
						break;
					case 3:
						destination = PoseidonBeach;
						posX = 1540;
						posY = 788;
						break;
					case 4:
						destination = PoseidonWater;
						posX = 1643;
						posY = 2032;
						break;
				}
				interaction.click.add(Command.create( loadScene, destination, posX, posY ));		
				interaction.over.add( playHoverSound );
			}
			
			// Remove portal to scenes you have not been yet
			if( !super.shellApi.checkEvent( _events.SAW_POSEIDON_BLOCK ))
			{
				super.removeEntity( super.getEntityById( "scene4" ));
			}
		
			if( !super.shellApi.checkEvent( _events.SAW_CERBERUS ))
			{
				super.removeEntity( super.getEntityById( "scene2" ));
			}
		}
		
		private function playHoverSound( entity:Entity ):void
		{
			super.shellApi.triggerEvent( "mirror_hover" );
		}
		
		private function loadScene( entity:Entity, destination:Class, posX:Number, posY:Number ):void
		{
			if( _withHerc )
			{
				checkWithHerc( destination );
			}
			
			if( _hercAgrees )
			{
				if( _withHerc )
				{
					super.shellApi.triggerEvent( _events.TELEPORT_HERC, true );
				}
				
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM)
				{
					var transportGroup:TransportGroup = super.shellApi.sceneManager.currentScene.addChildGroup( new TransportGroup() ) as TransportGroup;
					transportGroup.targetScene = destination;
					transportGroup.transportOut( super.shellApi.player, true, posX, posY, direction ); 
					
					if( _withHerc )
					{
						transportGroup.transportOut( super.shellApi.sceneManager.currentScene.getEntityById( "herc" ), false );
					}
				}
				else
				{
					this.shellApi.triggerEvent(_events.TELEPORT, true);
					this.shellApi.loadScene(destination, posX, posY, direction);
				}
				close();
			}
			
			else
			{
				super.shellApi.triggerEvent( _dialogEvent );
				close();
			}
		}
		
		private function checkWithHerc( destination:Class ):void
		{
			switch( destination )
			{
				case PoseidonBeach:
					_dialogEvent =_events.NOT_APHRODITE;
					_hercAgrees = false;
					break;
				case Cerberus:
					if( super.shellApi.checkEvent( _events.HADES_THRONE_OPEN ))
					{
						_dialogEvent = _events.NOT_HADES;
						_hercAgrees = false;
					}
					else
					{
						super.shellApi.triggerEvent( _events.HERCULES_UNDERGROUND, true );
					}
					break;
				case PoseidonWater:
					if( super.shellApi.checkEvent( _events.POSEIDON_THRONE_OPEN ))
					{
						_dialogEvent = _events.NOT_POSEIDON;
						_hercAgrees = false;
					}
					else
					{
						super.shellApi.triggerEvent( _events.HERCULES_UNDERWATER, true );
					}
					break;
				case MainStreet:
					if( !super.shellApi.checkEvent( _events.READY_TO_FACE_ZEUS ))
					{
						_dialogEvent = _events.NOT_ZEUS;
						_hercAgrees = false;
					}
					else
					{
						super.shellApi.triggerEvent( _events.HERCULES_MAIN_STREET, true );
					}
					break;
			}
			
		}
		
		private var direction:String = "right";
		private var _withHerc:Boolean;
		private var _dialogEvent:String = "";
		private var _hercAgrees:Boolean = true;
		private var characterDialogGroup:CharacterDialogGroup;
		
		private var _events:MythEvents;
	}
}