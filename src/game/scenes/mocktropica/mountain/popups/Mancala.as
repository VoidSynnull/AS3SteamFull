package game.scenes.mocktropica.mountain.popups
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.motion.Color;
	
	import game.components.motion.FollowTarget;
	import game.components.entity.Children;
	import game.components.entity.Parent;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.display.BitmapWrapper;
	import game.scene.SceneSound;
	import game.scenes.mocktropica.mountain.components.MancalaBeadComponent;
	import game.scenes.mocktropica.mountain.components.MancalaBugComponent;
	import game.scenes.mocktropica.mountain.components.MancalaPitComponent;
	import game.scenes.mocktropica.mountain.systems.MancalaBeadSystem;
	import game.scenes.mocktropica.mountain.systems.MancalaSystem;
	import game.systems.SystemPriorities;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class Mancala extends Popup
	{
		public function Mancala( container:DisplayObjectContainer = null )
		{
			super(container);
		}
		
		override public function destroy():void
		{
			complete.removeAll();
			complete = null;
			
			fail.removeAll();
			fail = null;
			
			super.destroy();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			complete = new Signal();
			fail = new Signal();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/mocktropica/mountain/";
			super.init( container );
			super.autoOpen = false;
			load();
		}
		
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce( loaded );
			super.loadFiles( new Array( "mancala.swf" ));
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "mancala.swf", true ) as MovieClip;
			super.layout.centerUI( super.screen.content );
			loadCloseButton();
			
			createPits();
			createBugs();
			createBeads();
			createHUD();
	
			super.addSystem( new BitmapSequenceSystem(), SystemPriorities.animate );
			super.addSystem( new MancalaSystem(), SystemPriorities.move );
			super.addSystem( new MancalaBeadSystem(), SystemPriorities.move );
			super.loaded();
			super.open();
		}
		
		private function createPits():void
		{
			var entity:Entity;
			var pointerEnt:Entity;
			var clickEnt:Entity;
			var interaction:Interaction;
			var number:int;
			var children:Children;
			var pit:MancalaPitComponent;
			
			// create pits
			for( number = 1; number < 15; number ++ )
			{
				pit = new MancalaPitComponent();
				entity = EntityUtils.createSpatialEntity( this, super.screen.content.getChildByName( "pit" + number ));
				entity.add( new Id( "pit" + number )).add( new Children());
				
				clickEnt = EntityUtils.createSpatialEntity( this, screen.content.getChildByName( "click" + number ));
				clickEnt.add( new Id( "click" + number ))
				InteractionCreator.addToEntity( clickEnt, [ InteractionCreator.UP, InteractionCreator.OVER, InteractionCreator.DOWN, InteractionCreator.OUT, InteractionCreator.CLICK ]);
				interaction = clickEnt.get( Interaction );
				interaction.over.add( showScore );
				
				interaction.out.add( fadeScore );
				
				if( number < 7 )
				{
					clickEnt.add( new Children( entity ));
					
				 	ToolTipCreator.addToEntity( clickEnt );
					interaction.downNative.add( Command.create( removeBeads, entity ));
				}
				
				entity.add( pit );
			}
			
			// point them to each other
			entity = super.getEntityById( "pit1" );
			
			pit = entity.get( MancalaPitComponent );
			pit.nextPit = super.getEntityById( "pit2" );
			pit.oppositePit = super.getEntityById( "pit13" );
			
			for( number = 2; number < 14; number ++ )
			{
				entity = super.getEntityById( "pit" + number );
				pit = entity.get( MancalaPitComponent );
				pit.nextPit = super.getEntityById( "pit" + ( number + 1 ));
				
				if( number != 7 )
				{
					pit.oppositePit = super.getEntityById( "pit" + ( 13 - ( number - 1 )));
				}
			}
			
			entity = super.getEntityById( "pit14" );
			pit = entity.get( MancalaPitComponent );
			pit.nextPit = super.getEntityById( "pit1" );
		}
		
		
		private function createBugs():void
		{
			var number:int;
			var entity:Entity;
			var timeline:Timeline;
			var property:String;
			var operator:String;
			var motion:Motion;
			var bug:MancalaBugComponent;
			
			for( number = 0; number < 4; number ++ )
			{
				entity = EntityUtils.createMovingEntity( this, MovieClip( MovieClip( super.screen.content ).getChildByName( "ladybug" + number )), super.screen.content.bugEmpty );
				entity.add( new Id( "ladybug" + number ));
				
				TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( entity )), this, entity );
				timeline = entity.get( Timeline );
				timeline.gotoAndPlay( Math.random() * 35 );
				
				bug = new MancalaBugComponent();
				bug.state = bug.HIDDEN;
				Display( entity.get( Display )).visible = false;
				entity.add( bug ).add( new Tween());
				Sleep( entity.get( Sleep )).ignoreOffscreenSleep = true;
			}			
		}
		
		// bitmap it and redraw it for all the beads
		private function createBeads():void
		{
			var entity:Entity;
			var displayObject:DisplayObjectContainer;
			var sprite:Sprite;
			var bitmapData:BitmapData;
			var clip:MovieClip = super.screen.content.bead;
			var wrapper:BitmapWrapper = this.convertToBitmapSprite( clip );
			var spatial:Spatial;
			var parent:Parent;
			var children:Children;
			var bug:MancalaBugComponent;
			
			var startX:Number;
			var startY:Number;
			var number:int;
			var pitNumber:int = 1;
			var counter:int = 0;
						
			var displayObjectBounds:Rectangle = wrapper.sprite.getBounds( wrapper.sprite );
			var offsetMatrix : Matrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
			var bitmap:Bitmap;
			var color:Color;
			var tint:uint;
						
			for( number = 0; number < 48; number ++ ) 
			{
				sprite = new Sprite();
				bitmapData = new BitmapData( wrapper.sprite.width, wrapper.sprite.height, true, 0x000000 );
				
				if( Math.random() > .5 )
				{
					tint = 0xFFFFFF;
				}
				else
				{
					tint = 0x000000;
				}
				
				color = new Color();
				color.setTint( tint, Math.random() * .2 );
				bitmapData.draw( wrapper.data, null, color );
				
				bitmap = new Bitmap( bitmapData, "auto", true );
				bitmap.transform.matrix = offsetMatrix;
				sprite.addChild( bitmap );
				
				if( counter == 4 ) 
				{
					pitNumber ++;
					if( pitNumber == 7 )
					{
						pitNumber ++;
					}
					counter = 0;
				}
				counter ++;
				
				entity = getEntityById( "pit" + pitNumber );
				children = entity.get( Children );
				parent = new Parent( entity );
				
				displayObject = EntityUtils.getDisplayObject( entity );
				
				if( Math.random() * 100 < 92 || bugCount > 3 ) 
				{
					entity = EntityUtils.createSpatialEntity( this, sprite, super.screen.content.beadEmpty );   
		
					spatial = entity.get( Spatial );
					spatial.scale = ( Math.random() + 4 ) / 5;
					spatial.rotation = ( Math.random() * 360 ) - 180;
			 		
					startX = displayObject.x + ( Math.random() * displayObject.width ) - ( .5 * displayObject.width );
					startY = displayObject.y + ( Math.random() * displayObject.height ) - ( .5 * displayObject.height );
					EntityUtils.position( entity, startX, startY );
					
					entity.add( parent ).add( new Id( "bead" + number )).add( new Tween()).add( new MancalaBeadComponent()); 
					children.children.push( entity );
				}
				
				else
				{
					entity = super.getEntityById( "ladybug" + bugCount );
					
					startX = displayObject.x;
					startY = displayObject.y;
					EntityUtils.position( entity, startX, startY );
					
					spatial = entity.get( Spatial );
					
					bugCount++;
					
					bug = entity.get( MancalaBugComponent );
					bug.state = bug.SEEK;
					Display( entity.get( Display )).visible = true;
					bug.start = new Point( spatial.x, spatial.y );
					
					children.children.push( entity );
				}
			}
			
			wrapper.sprite.visible = false;
			wrapper.bitmap.visible = false;
		}
		
		private function createHUD():void
		{
			var clip:MovieClip;
			var display:Display;
			var entity:Entity;
			var number:int;
			var textField:TextField;
			var inputEntity:Entity;
			var followTarget:FollowTarget;
			var timeline:Timeline;
			var spatial:Spatial;
			
			// PLAYER TURN
			_playerTurnEnt = EntityUtils.createSpatialEntity( this, super.screen.content.yt );
			_playerTurnEnt.add( new Id( "playerTurn" ));
			
			// CODER TURN
			_coderTurnEnt = EntityUtils.createSpatialEntity( this, super.screen.content.ot );
			_coderTurnEnt.add( new Id( "coderTurn" ));
			display = _coderTurnEnt.get( Display );
			display.visible = false;
			
			// PLAYER CUP GLOWS
			for( number = 1; number < 8; number ++ )
			{
				clip = super.screen.content.getChildByName( "glow" + number );
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "glow" + number ));
				TimelineUtils.convertClip( clip, this, entity );
				timeline = entity.get( Timeline );
				timeline.gotoAndPlay( 30 - ( number * 3 ));
			}
			
			// ALL CUPS GLOW
			entity = EntityUtils.createSpatialEntity( this, super.screen.content.cupGlow );
			entity.add( new Id( "cupGlow" ));
			display = entity.get( Display );
			display.alpha = 0;			
			
			// GAME RESULTS TEXT ENTITY
			entity = EntityUtils.createSpatialEntity( this, super.screen.content.endClip );
			entity.add( new Id( "endClip" ));
			display = entity.get( Display );
			display.visible = false;
			
			// PLAYER SCORE TEXT ENTITY
			textField = TextUtils.refreshText( super.screen.content.amount1.fldAmount );	
			textField.embedFonts = true;
			textField.defaultTextFormat = new TextFormat("Billy Serif", 20, 0x37372f);
			
			entity = EntityUtils.createSpatialEntity( this, super.screen.content.amount1 );
			entity.add( new Id( "playerScore" ));
			entity.add( new MancalaTextField(textField) );
			display = entity.get( Display );
			display.visible = false;
			
			// CODER SCORE TEXT ENTITY
			textField = TextUtils.refreshText( super.screen.content.amount2.fldAmount );	
			textField.embedFonts = true;
			textField.defaultTextFormat = new TextFormat("Billy Serif", 20, 0x37372f);
			
			entity = EntityUtils.createSpatialEntity( this, super.screen.content.amount2 );
			entity.add( new Id( "coderScore" ));
			entity.add( new MancalaTextField(textField) );
			display = entity.get( Display );
			display.visible = false;
			
			// CUP VALUE TEXT ENTITY
			textField = TextUtils.refreshText( super.screen.content.amount.fldAmount );	
			textField.embedFonts = true;
			textField.defaultTextFormat = new TextFormat("Billy Serif", 20, 0x37372f);
		
			_scoreEnt = EntityUtils.createSpatialEntity( this, super.screen.content.amount );
			_scoreEnt.add( new Id( "score" ));
			_scoreEnt.add( new MancalaTextField(textField) );
			display = _scoreEnt.get( Display );
			display.displayObject.mouseEnabled = false;
			display.displayObject.mouseChildren = false;
			display.visible = false;
			
			inputEntity = super.shellApi.inputEntity;
			spatial = inputEntity.get( Spatial );
			
			followTarget = new FollowTarget( spatial );
			followTarget.offset = new Point( -25, -150 );
			_scoreEnt.add( followTarget );
			
			// HINTS ENTITY - ARROW FRONT
			_arrowFront = EntityUtils.createSpatialEntity( this, super.screen.content.arrowFront );
			_arrowFront.add( new Id( "arrowFront" ));
			
			followTarget = new FollowTarget( spatial );
			followTarget.properties = new Vector.<String>;
			followTarget.properties.push( "x" );
			_arrowFront.add( followTarget );
			
			// HINTS ENTITY - ARROW BACK
			_arrowBack = EntityUtils.createSpatialEntity( this, super.screen.content.arrowBack );
			_arrowBack.add( new Id( "arrowBack" ));
			_arrowBack.add( followTarget );
			
			// HINTS TEXT ENTITY
			textField = TextUtils.refreshText( super.screen.content.hintText.fldHint );	
			textField.embedFonts = true;
			textField.defaultTextFormat = new TextFormat("Billy Serif", 14, 0x37372f);
			textField.htmlText = INTRO_TEXT;
			textField.height = textField.textHeight + 20;
			
			_hintText = EntityUtils.createSpatialEntity( this, super.screen.content.hintText );
			_hintText.add( new Id( "hintText" ));
			_hintText.add( new MancalaTextField(textField) );
			
			followTarget = new FollowTarget( spatial, .25 );
			followTarget.properties = new Vector.<String>;
			followTarget.properties.push( "x" );
			_hintText.add( followTarget );
			
			// HINTS DISPLAY ENTITY
			_hintDisplay = EntityUtils.createSpatialEntity( this, super.screen.content.hints );
			Spatial( _hintDisplay.get( Spatial )).height = textField.height;// + 10;
			_hintDisplay.add( new Id( "hintDisplay" ));
			_hintDisplay.add( followTarget );
		}
		
		/**
		 *  SCORE HANDLER
		 **/
		
		private function showScore( entity:Entity ):void
		{
			var pitNum:Number = entity.get( Id ).id.slice( 5 );
			var pitEnt:Entity = super.getEntityById( "pit" + pitNum );
			var value:Number = pitEnt.get( Children ).children.length;
			
			if( value > 0 )
			{
				updateHud( new String( value ));
			}
		}
		
		private function updateHud( value:String ):void
		{	
			var textField:MancalaTextField = _scoreEnt.get( MancalaTextField );
			var display:Display = _scoreEnt.get( Display );
			textField.text.htmlText = value;
			display.visible = true;	
		}
		
		private function fadeScore( entity:Entity ):void
		{
			var display:Display = _scoreEnt.get( Display );
			display.visible = false;
		}
		
		/**
		 * GAMEPLAY
		 **/
		private function removeBeads( event:MouseEvent = null, pitEnt:Entity = null ):void
		{
			if( !firstMove )
			{
				killGlows();
				firstMove = true;
			}
			var mancalaPit:MancalaPitComponent = pitEnt.get( MancalaPitComponent );
			var display:Display;
			var children:Children = pitEnt.get( Children );
			
			display = _hintText.get( Display );
			display.visible = false;
			display = _hintDisplay.get( Display );
			display.visible = false;
			display = _arrowFront.get( Display );
			display.visible = false;
			display = _arrowBack.get( Display );
			display.visible = false;
			
			display = _scoreEnt.get( Display );
			display.visible = false;
			
			if( playerTurn )
			{				
				if( children.children.length > 0 && !locked )
				{
					locked = true;
					display = _playerTurnEnt.get( Display );
					display.visible = false;
					SceneUtil.lockInput( this );
					moveBeads( children.children, mancalaPit.nextPit.get( Id ).id );
				}
			}
			
			else if( !event && !playerTurn )
			{
				moveBeads( children.children, mancalaPit.nextPit.get( Id ).id );
			}
		}
		
		private function codersMove():void
		{
			var number:int;
			var pitEnt:Entity;
			var checkEnt:Entity;
			var numCheck:int;
			
			for( number = 13; number >= 8; number -- )
			{
				pitEnt = getEntityById( "pit" + number );
				numCheck = number + pitEnt.get( Children ).children.length;
				checkEnt = getEntityById( "pit" + numCheck );
				
				if( numCheck < 14 && checkEnt.get( Children ).children.length == 0 && number != numCheck )
				{
					removeBeads( null, pitEnt );
					return;
				}
			}
			
			for( number = 13; number >= 8; number -- )
			{
				pitEnt = getEntityById( "pit" + number );
				if( number + pitEnt.get( Children ).children.length == 14 )
				{
					removeBeads( null, pitEnt );
					return;
				}
			}
			
			for( number = 13; number >= 8; number -- )
			{
				pitEnt = getEntityById( "pit" + number );
				if( pitEnt.get( Children ).children.length > 0 )
				{
					removeBeads( null, pitEnt );
					return;
				}
			}
			
			do{
				numCheck = Math.ceil( Math.random() * 6 ) + 7;
				pitEnt = getEntityById( "pit" + numCheck );
			} while ( pitEnt.get( Children ).children.length == 0 )
			
			removeBeads( null, pitEnt );
		}
		
		private function killGlows():void
		{
			var number:int;
			var entity:Entity;
			var timeline:Timeline;
			
			for( number = 1; number < 8; number ++ )
			{
				entity = getEntityById( "glow" + number );
				timeline = entity.get( Timeline );
				timeline.gotoAndStop( 40 );
			}
		}
		
		private function moveBeads( children:Vector.<Entity>, nextPitId:String ):void
		{
			var pitEnt:Entity = getEntityById( nextPitId );
			var pitSpatial:Spatial = pitEnt.get( Spatial );
			var beadEnt:Entity;
			var spatial:Spatial;
			var newStack:Vector.<Entity> = new Vector.<Entity>;
			var tween:Tween;
			var displayObject:DisplayObjectContainer; 
			var endingMove:Boolean = false;
			var handler:Function = null;
			var params:Array = null;
			var moveX:Number;
			var moveY:Number;
			var random:Number;
			var audio:Audio = AudioUtils.getAudio( this, SceneSound.SCENE_SOUND );
			var path:String;
			
			if( children.length > 4 )
			{
				random = Math.round( Math.random()) + 1;
				path = SoundManager.EFFECTS_PATH + SMALL_MULTI_STONE + random + ".mp3";
			}
			else if( children.length > 1 )
			{
				random = Math.round( Math.random() * 2 ) + 1;
				path = SoundManager.EFFECTS_PATH + LARGE_MULTI_STONE + random + ".mp3";
			}
			else if( children.length == 1 )
			{
				endingMove = true;
				random = Math.round( Math.random() * 5 ) + 1;
				path = SoundManager.EFFECTS_PATH + SINGLE_STONE + random + ".mp3";
			}
			
			audio.play( path );
			
			if(( nextPitId == "pit7" && playerTurn ) || ( nextPitId == "pit14" && !playerTurn ))
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "a.mp3";
				audio.play( path, false, null, 4 );
			}
			
			while ( children.length > 0 )
			{
				beadEnt = children.pop();
				newStack.push( beadEnt );
				spatial = beadEnt.get( Spatial );
				displayObject = EntityUtils.getDisplayObject( beadEnt );
				
				DisplayUtils.moveToTop( displayObject );
				
				tween = beadEnt.get( Tween );
				
				if( nextPitId == "pit14" && playerTurn )
				{
					nextPitId = "pit1";
					pitEnt = getEntityById( nextPitId );
					pitSpatial = pitEnt.get( Spatial );
				}
				
				else if ( nextPitId == "pit7" && !playerTurn )
				{
					nextPitId = "pit8";
					pitEnt = getEntityById( nextPitId );
					pitSpatial = pitEnt.get( Spatial );	
				}
		
				if( children.length == 0 )
				{
					if( !endingMove )
					{
						handler = leaveBead;
						params = new Array( newStack, nextPitId, false );
					}
					else
					{
						if(( playerTurn && nextPitId == "pit7" ) || ( !playerTurn && nextPitId == "pit14" ))
						{
							handler = leaveBead;
							params = new Array( newStack, nextPitId, true );
						}
						else
						{
							handler = checkPoints;
							params = new Array( beadEnt, nextPitId );
						}				
					}
				}
				
				displayObject = EntityUtils.getDisplayObject( pitEnt );
				moveX = pitSpatial.x  + ( Math.random() * displayObject.width ) - ( .5 * displayObject.width );
				moveY = pitSpatial.y  + ( Math.random() * displayObject.height ) - ( .5 * displayObject.height );
				tween.to( spatial, MOVE_TIME, { x : moveX, y : moveY });
				tween.to( spatial, SHRINK_TIME, { scale : spatial.scale * 2, onComplete : shrinkTween, onCompleteParams : [ beadEnt, handler, params ]});
			}
		}
		
		private function shrinkTween( beadEnt:Entity, handler:Function = null, params:Array = null ):void
		{
			var spatial:Spatial = beadEnt.get( Spatial );
			var tween:Tween = beadEnt.get( Tween );
			
			tween.to( spatial, SHRINK_TIME, { scale : spatial.scale * .5, onComplete : handler, onCompleteParams : params });
		}
		
		private function leaveBead( stack:Vector.<Entity>, pitId:String, boardCheck:Boolean = true ):void
		{
			var entity:Entity = stack.pop();
			var spatial:Spatial = entity.get( Spatial );
			
			var followTarget:FollowTarget;
			var textField:MancalaTextField = _hintText.get( MancalaTextField );
			var display:Display;
			
			var pitEnt:Entity = getEntityById( pitId );
			var pitSpatial:Spatial = pitEnt.get( Spatial );
			
			var bead:MancalaBeadComponent = entity.get( MancalaBeadComponent );
			var bug:MancalaBugComponent = entity.get( MancalaBugComponent );
			
			if( bead )
			{
				bead.state = bead.SHAKE;
				bead.magnitude = Math.random() + 1.5;
				bead.start = new Point( spatial.x, spatial.y );
			}
			
			if( bug )
			{
				bug.state = bug.SEEK;
				bug.start = new Point( pitSpatial.x, pitSpatial.y );
			}
			
			pitEnt.get( Children ).children.push( entity );

			if( !boardCheck )
			{
				var pitNum:Number = DataUtils.getNumber( pitId.slice( 3 ));
				pitNum ++;
				
				if( pitNum == 15 )
				{
					pitNum = 1;
				}
				
				moveBeads( stack, "pit" + pitNum );
			}	
			else
			{
				if( pitId == "pit7" )
				{
					textField.text.htmlText = YOU_EXTRA_MOVE;
					textField.text.height = textField.text.textHeight + 20;
					
					_hintDisplay.remove( FollowTarget );
					spatial = _hintDisplay.get( Spatial );
					spatial.height = textField.text.height;
					spatial.x = pitSpatial.x;
					display = _hintDisplay.get( Display );
					display.visible = true;
					
					_hintText.remove( FollowTarget );
					spatial = _hintText.get( Spatial );
					spatial.x = pitSpatial.x;
					display = _hintText.get( Display );
					display.visible = true;

					_arrowFront.remove( FollowTarget );
					spatial = _arrowFront.get( Spatial );
					spatial.x = pitSpatial.x;
					display = _arrowFront.get( Display );
					display.visible = true;

					_arrowBack.remove( FollowTarget );
					spatial = _arrowBack.get( Spatial );
					spatial.x = pitSpatial.x;
					display = _arrowBack.get( Display );
					display.visible = true;			
				}
				else
				{
					textField.text.htmlText = CODER_EXTRA_MOVE;
					textField.text.height = textField.text.textHeight + 20;
					
					_hintDisplay.remove( FollowTarget );
					spatial = _hintDisplay.get( Spatial );
					spatial.height = textField.text.height;
					spatial.x = pitSpatial.x;
					display = _hintDisplay.get( Display );
					display.visible = true;
					
					_hintText.remove( FollowTarget );
					spatial = _hintText.get( Spatial );
					spatial.x = pitSpatial.x;
					display = _hintText.get( Display );
					display.visible = true;
					
					_arrowFront.remove( FollowTarget );
					spatial = _arrowFront.get( Spatial );
					spatial.x = pitSpatial.x;
					display = _arrowFront.get( Display );
					display.visible = true;
					
					_arrowBack.remove( FollowTarget );
					spatial = _arrowBack.get( Spatial );
					spatial.x = pitSpatial.x;
					display = _arrowBack.get( Display );
					display.visible = true;
				}
				
				checkBoard( checkBoard );
			}
		}
	
		private function shakeBead( entity:Entity, pitSpatial:Spatial ):void
		{
			_arrowBack.remove( FollowTarget );
			_arrowFront.remove( FollowTarget );
			_hintText.remove( FollowTarget );
			_hintDisplay.remove( FollowTarget );
			
			var bead:MancalaBeadComponent = entity.get( MancalaBeadComponent );
			var bug:MancalaBugComponent = entity.get( MancalaBugComponent );
			var spatial:Spatial;
			
			if( bead )
			{
				spatial = entity.get( Spatial );
				bead.state = bead.SHAKE;			
				bead.magnitude = Math.random() + 1.5;
				bead.start = new Point( spatial.x, spatial.y );
			}
			
			if( bug )
			{
				bug.state = bug.SEEK;
				bug.start = new Point( pitSpatial.x, pitSpatial.y );
			}
		}
		
		// LAND ON EMPTY PIT
		private function checkPoints( beadEnt:Entity, pitId:String ):void
		{
			var display:Display;
			var textField:MancalaTextField;
			var followTarget:FollowTarget;
			
			var pitEnt:Entity = getEntityById( pitId );
			var pitNum:Number = DataUtils.getNumber( pitId.slice( 3 )); 
			
			var children:Children = pitEnt.get( Children );
			var spatial:Spatial = beadEnt.get( Spatial );

			var newStack:Vector.<Entity> = new Vector.<Entity>;
			newStack.push( beadEnt );
			
			var bead:MancalaBeadComponent = beadEnt.get( MancalaBeadComponent );
			var bug:MancalaBugComponent = beadEnt.get( MancalaBugComponent );
			if( bead )
			{
				bead.state = bead.SHAKE;
				bead.magnitude = Math.random() + 1.5;
			
				bead.start = new Point( spatial.x, spatial.y );
			}
			
			if( bug )
			{
				bug.state = bug.SEEK;	
				bug.start = new Point( spatial.x, spatial.y );
			}
			
			if( playerTurn )
			{
				textField = _hintText.get( MancalaTextField );
				textField.text.htmlText = YOU_CAPTURE;
				textField.text.height = textField.text.textHeight + 20;
			}
			else
			{				
				textField = _hintText.get( MancalaTextField );
				textField.text.htmlText = CODER_CAPTURE;
				textField.text.height = textField.text.textHeight + 20;
			}

			if( ( 0 < pitNum && pitNum < 7 && children.children.length == 0 && playerTurn ) || ( 7 < pitNum && pitNum < 14 && children.children.length == 0 && !playerTurn ))
			{
				
				Display( _hintText.get( Display )).visible = true;
				Spatial( _hintText.get( Spatial )).x = spatial.x;
				
				Display( _hintDisplay.get( Display )).visible = true;
				Spatial( _hintDisplay.get( Spatial )).x = spatial.x;
				Spatial( _hintDisplay.get( Spatial )).height = textField.text.height;
				
				Display( _arrowFront.get( Display )).visible = true;
				Spatial( _arrowFront.get( Spatial )).x = spatial.x;
				
				Display( _arrowBack.get( Display )).visible = true;
				Spatial( _arrowBack.get( Spatial )).x = spatial.x;
				
				callLoopGlow( beadEnt, pitId );
			}
				
			else
			{
				getEntityById( pitId ).get( Children ).children.push( beadEnt );
				checkBoard( );
			}
		}
		
		private function callLoopGlow( beadEnt:Entity, pitId:String ):void
		{
			var pitEnt:Entity = super.getEntityById( pitId );
			var entity:Entity = super.getEntityById( "cupGlow" );
			var display:Display;
			var spatial:Spatial = pitEnt.get( Spatial );
			var glowSpatial:Spatial;
			var tween:Tween;
			
			glowSpatial = entity.get( Spatial );
			glowSpatial.x = spatial.x;
			display = entity.get( Display );
			
			tween = entity.get( Tween );
			
			if( !tween )
			{
				tween = new Tween();
				entity.add( tween );
			}
			tween.to( display, FADE_TIME, { alpha : 1, onComplete : fadeLoopGlow, onCompleteParams : [ beadEnt, pitId ]});
		}
		
		private function fadeLoopGlow( beadEnt:Entity, pitId:String ):void
		{
			var entity:Entity;
			var display:Display;
			var spatial:Spatial = beadEnt.get( Spatial );
			var tween:Tween;
			var bug:MancalaBugComponent;
			var bead:MancalaBeadComponent;
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			var path:String;
			
			bead = beadEnt.get( MancalaBeadComponent );
			bug = beadEnt.get( MancalaBugComponent );
			if( bead )
			{
				bead.state = bead.IDLE;
			}
			
			var displayObject:DisplayObjectContainer;
			var pitSpatial:Spatial;
			var moveX:Number;
			var moveY:Number;
			
			var pitEnt:Entity = getEntityById( pitId );
			var pit:MancalaPitComponent = pitEnt.get( MancalaPitComponent );
			var children:Children = pitEnt.get( Children );
			var oPChildren:Children = pit.oppositePit.get( Children );
			var goalChildren:Children;
			var followTarget:FollowTarget;
			var params:Array = null;
			
			entity = getEntityById( "cupGlow" );
			tween = entity.get( Tween );
			display = entity.get( Display );
			tween.to( display, FADE_TIME, { alpha : 0 });
			
			if( playerTurn )
			{
				pitEnt = getEntityById( "pit7" );
				goalChildren = pitEnt.get( Children );
				pitSpatial = pitEnt.get( Spatial );
			}
			else
			{
				pitEnt = getEntityById( "pit14" );
				goalChildren = pitEnt.get( Children );
				pitSpatial = pitEnt.get( Spatial );
			}
			displayObject = EntityUtils.getDisplayObject( pitEnt );
			
			goalChildren.children.push( beadEnt );
			tween = beadEnt.get( Tween );

			moveX = pitSpatial.x  + ( Math.random() * displayObject.width ) - ( .5 * displayObject.width );
			moveY = pitSpatial.y  + ( Math.random() * displayObject.height ) - ( .5 * displayObject.height );
			
			params = new Array( beadEnt, pitSpatial );
			tween.to( spatial, MOVE_TIME, { x : moveX, y : moveY });//, onComplete : shakeBead, onCompleteParams : [ beadEnt, pitSpatial ]});
			tween.to( spatial, SHRINK_TIME, { scale : spatial.scale * 2, onComplete : shrinkTween, onCompleteParams : [ beadEnt, shakeBead, params ]});
			
			// HAVE HINTS FOLLOW THE BEADS TO THE GOAL
			followTarget = new FollowTarget( spatial, .25 );
			followTarget.properties = new Vector.<String>;
			followTarget.properties.push( "x" );
			_hintText.add( followTarget );
			_hintDisplay.add( followTarget );

			followTarget = new FollowTarget( spatial );
			followTarget.properties = new Vector.<String>;
			followTarget.properties.push( "x" );
			_arrowFront.add( followTarget );
			_arrowBack.add( followTarget );
			
			
			if( oPChildren.children.length > 3 )
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "c.mp3";
			}
			else if( oPChildren.children.length > 1 )
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "b.mp3";
			}
			else
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "a.mp3";
			}
			
			audio.play( path, false, null, 4 );
			
			while ( oPChildren.children.length > 0 )
			{
				beadEnt = oPChildren.children.pop();
				bug = beadEnt.get( MancalaBugComponent );
				tween = beadEnt.get( Tween );
				spatial = beadEnt.get( Spatial );
				
				if( bug )
				{
					bug.state = bug.PANIC;
					path = SoundManager.EFFECTS_PATH + BEETLE_FLIGHT;
					audio.play( path );
				}
				else
				{
					goalChildren.children.push( beadEnt );
					
					moveX = pitSpatial.x  + ( Math.random() * displayObject.width ) - ( .5 * displayObject.width );
					moveY = pitSpatial.y  + ( Math.random() * displayObject.height ) - ( .5 * displayObject.height );
					
					params = new Array( beadEnt, pitSpatial );
					tween.to( spatial, MOVE_TIME, { x : moveX, y : moveY });
					tween.to( spatial, SHRINK_TIME, { scale : spatial.scale * 2, onComplete : shrinkTween, onCompleteParams : [ beadEnt, shakeBead, params ]});
				}
			}
			
			checkBoard( );
		}
		
		private function checkBoard( extraTurn:Boolean = false ):void
		{
			var number:int;
			var entity:Entity;
			var children:Children;
			var playerCount:int = 0;
			var count:int = 0;
			var bead:MancalaBeadComponent;
			
			var textField:MancalaTextField = _hintText.get( MancalaTextField );
			var spatial:Spatial = _hintDisplay.get( Spatial );
			
			for( number = 1; number < 7; number ++ )
			{
				entity = getEntityById( "pit" + number );
				children = entity.get( Children );
			
				if( children.children.length == 0 )
				{
					playerCount++;
				}
			}
			
			for( number = 8; number < 14; number ++ )
			{
				entity = getEntityById( "pit" + number );
				children = entity.get( Children );
				
				if( children.children.length == 0 )
				{
					count++;
				}
			}
			
			for( number = 0; number < 48; number ++ )
			{
				entity = getEntityById( "bead" + number );
				if( entity )
				{
					bead = entity.get( MancalaBeadComponent );
					if( bead )
					{
						bead.state = bead.IDLE;
					}
				}
			}
			
			if( count == 6 ) 
			{
				textField.text.htmlText = YOU_FINISHER;
				textField.text.height = textField.text.textHeight + 20;
				
				spatial.height = textField.text.height;
				endGame();
			}
			else if( playerCount == 6 )
			{
				textField.text.htmlText = CODER_FINISHER;
				textField.text.height = textField.text.textHeight + 20;
				
				spatial.height = textField.text.height;
				endGame();
			}
			
			else
			{
				if( playerTurn && extraTurn || !playerTurn && !extraTurn )
				{
					playerTurn = true;
					locked = false;
					SceneUtil.lockInput( this, false );
					
					Display( _playerTurnEnt.get( Display )).visible = true;
					Display( _coderTurnEnt.get( Display )).visible = false;
				}
				
				else
				{
					playerTurn = false;
					locked = true;
					
					codersMove();
					
					Display( _playerTurnEnt.get( Display )).visible = false;
					Display( _coderTurnEnt.get( Display )).visible = true;
				}	
			}
		}
		
		private function endGame():void
		{
			var number:int;
			var pitEnt:Entity;
			var entity:Entity;
			var children:Children; 
			var spatial:Spatial;
			var displayObject:DisplayObjectContainer;
			var goalEnt:Entity;
			var goalChildren:Children;
			var goalSpatial:Spatial;
			var tween:Tween;
			var bug:MancalaBugComponent;
			
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			var path:String;
						
			var moveX:Number;
			var moveY:Number;
			var total:Number = 0;
			
			goalEnt = getEntityById( "pit7" );
			goalSpatial = goalEnt.get( Spatial );
			goalChildren = goalEnt.get( Children );
			
			SceneUtil.lockInput( this );
			for( number = 1; number < 7; number ++ )
			{
				pitEnt = getEntityById( "pit" + number );
				children = pitEnt.get( Children );
				total += children.children.length;
				
				while( children.children.length > 0 )
				{
					entity = children.children.pop();
					tween = entity.get( Tween );
					spatial = entity.get( Spatial );
					displayObject = EntityUtils.getDisplayObject( goalEnt );
					bug = entity.get( MancalaBugComponent );
					
					if( bug )
					{
						bug.state = bug.PANIC;
						path = SoundManager.EFFECTS_PATH + BEETLE_FLIGHT;
						audio.play( path );
					}
					else
					{
						goalChildren.children.push( entity );
						
						moveX = goalSpatial.x  + ( Math.random() * displayObject.width ) - ( .5 * displayObject.width );
						moveY = goalSpatial.y  + ( Math.random() * displayObject.height ) - ( .5 * displayObject.height );
						
						tween.to( spatial, MOVE_TIME, { x : moveX, y : moveY });
						tween.to( spatial, SHRINK_TIME, { scale : spatial.scale * 2, onComplete : shrinkTween, onCompleteParams : [ entity ]});
					}
				}
			}
			
			if( total > 3 )
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "c.mp3";
			}
			else if( total > 1 )
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "b.mp3";
			}
			else
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "a.mp3";
			}
			
			audio.play( path, false, null, 4 );
			total = 0;
			
			goalEnt = getEntityById( "pit14" );
			goalSpatial = goalEnt.get( Spatial );
			goalChildren = goalEnt.get( Children );
			
			for( number = 8; number < 14; number ++ )
			{
				pitEnt = getEntityById( "pit" + number );
				children = pitEnt.get( Children );
				total += children.children.length;
								
				while( children.children.length > 0 )
				{
					entity = children.children.pop();
					tween = entity.get( Tween );
					spatial = entity.get( Spatial );
					displayObject = EntityUtils.getDisplayObject( goalEnt );
					bug = entity.get( MancalaBugComponent );
					
					if( bug )
					{
						bug.state = bug.PANIC;
						path = SoundManager.EFFECTS_PATH + BEETLE_FLIGHT;
						audio.play( path );
					}
					else
					{
						goalChildren.children.push( entity );
						
						moveX = goalSpatial.x  + ( Math.random() * displayObject.width ) - ( .5 * displayObject.width );
						moveY = goalSpatial.y  + ( Math.random() * displayObject.height ) - ( .5 * displayObject.height );
						
						tween.to( spatial, MOVE_TIME, { x : moveX, y : moveY });
						tween.to( spatial, SHRINK_TIME, { scale : spatial.scale * 2, onComplete : shrinkTween, onCompleteParams : [ entity ]});
					}
				}
			}
			
			if( total > 3 )
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "c.mp3";
			}
			else if( total > 1 )
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "b.mp3";
			}
			else
			{
				path = SoundManager.EFFECTS_PATH + POINTS_PING + "a.mp3";
			}
			
			audio.play( path, false, null, 4 );
					
			showFinalScore( );
		}
		
		
		
		private function showFinalScore():void
		{
			var yourScore:Entity = getEntityById( "playerScore" );
			var yourGoal:Entity = getEntityById( "pit7" );
			
			var coderScore:Entity = getEntityById( "coderScore" );
			var coderGoal:Entity = getEntityById( "pit14" );
			
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			var path:String;
			
			var number:int;
			var clickEnt:Entity;
			var children:Children; 
			
			var yourValue:Number;
			var coderValue:Number;
			var textField:MancalaTextField;
			var spatial:Spatial;
			var display:Display;
			
			var goalSpatial:Spatial;
			
			yourValue = yourGoal.get( Children ).children.length;
			coderValue = coderGoal.get( Children ).children.length;
			
			textField = yourScore.get( MancalaTextField );
			textField.text.htmlText = new String( yourValue );
			Display( yourScore.get( Display )).visible = true;
			
			textField = coderScore.get( MancalaTextField );
			textField.text.htmlText = new String( coderValue );
			Display( coderScore.get( Display )).visible = true;
			
			
			Display( getEntityById( "endClip" ).get( Display )).visible = true;
			Display( _playerTurnEnt.get( Display )).visible = false;
			Display( _coderTurnEnt.get( Display )).visible = false;
			
			if( yourGoal.get( Children ).children.length > coderGoal.get( Children ).children.length )
			{
				resolveGame( "YOU WIN!!!", MINI_GAME_WIN, completeMancala );
			}
			
			else if( yourGoal.get( Children ).children.length < coderGoal.get( Children ).children.length )
			{
				resolveGame( "YOU LOST", MINI_GAME_LOSS, failMancala );
			}
			else
			{
				resolveGame( "TIE GAME", MINI_GAME_LOSS, failMancala );
			}
			
			for( number = 1; number < 7; number ++ )
			{
				clickEnt = getEntityById( "click" + number );
				children = clickEnt.get( Children );
				
				removeEntity( children.children[ 1 ]);
			}
			
			// CENTER HINTS AT END OF GAME
			goalSpatial = _playerTurnEnt.get( Spatial );
			
			_hintDisplay.remove( FollowTarget );
			spatial = _hintDisplay.get( Spatial );
			spatial.x = goalSpatial.x;
			display = _hintDisplay.get( Display );
			display.visible = true;
			
			_hintText.remove( FollowTarget );
			spatial = _hintText.get( Spatial );
			spatial.x = goalSpatial.x;
			display = _hintText.get( Display );
			display.visible = true;
			
			_arrowFront.remove( FollowTarget );
			display = _arrowFront.get( Display );
			display.visible = false;
			
			_arrowBack.remove( FollowTarget );
			display = _arrowBack.get( Display );
			display.visible = false;		
		}
		
		private function resolveGame( text:String, sound:String, handler:Function ):void
		{
			var audio:Audio = AudioUtils.getAudio( this, SceneSound.SCENE_SOUND );
			var path:String;
			if(sound != MINI_GAME_LOSS){
				path = SoundManager.MUSIC_PATH + sound;
			} else {
				path = SoundManager.EFFECTS_PATH + sound;
			}
			
			audio.play( path );
			setVictoryText( text );
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, handler ));
		}
		
		private function setVictoryText( text:String ):void
		{
			var textField:TextField;
			
			textField = TextUtils.refreshText( super.screen.content.endClip.fldFront );	
			textField.embedFonts = true;
			textField.defaultTextFormat = new TextFormat("Billy Serif", 24, 0xDADADA );
			textField.htmlText = text;
			
			textField = TextUtils.refreshText( super.screen.content.endClip.fldBack );	
			textField.embedFonts = true;
			textField.defaultTextFormat = new TextFormat("Billy Serif", 24, 0x422B1C );
			textField.htmlText = text;
		}
		
		private function failMancala():void
		{
			fail.dispatch();
		}
		
		private function completeMancala():void
		{
			complete.dispatch();
		}
		
		private var bugCount:uint = 0;
		private var firstMove:Boolean = false;
		private var locked:Boolean = false;
		private var playerTurn:Boolean = true;
		
		private var FADE_TIME:uint = 1;
		private var SHRINK_TIME:Number = .4;
		private var MOVE_TIME:Number = .8;
		
		public var complete:Signal;
		public var fail:Signal;
		
		private var _arrowFront:Entity;
		private var _arrowBack:Entity;
		private var _hintText:Entity;
		private var _hintDisplay:Entity;
		
		private const INTRO_TEXT:String =			"Select one of the 6 cups on your side (the bottom).<br><br>Your goal is to get the most stones in your tray on the right side.";
		private const YOU_CAPTURE:String =			"You ended in an empty cup on your side and captured the stones from that cup and the one across from it.";
		private const CODER_CAPTURE:String =		"Your opponent ended in an empty cup on his side and captured the stones from that cup and the one across from it."
		private const YOU_EXTRA_MOVE:String =		"You ended in your tray. You get to go again!";
		private const CODER_EXTRA_MOVE:String =		"Your opponent ended in his tray. He gets to go again.";
		private const YOU_FINISHER:String =			"The game ends when all the cups on one side are empty. You captured all the stones remaining on your side!";
		private const CODER_FINISHER:String =		"The game ends when all the cups on one side are empty. Your opponent captured all the stones remaining on his side.";
		
		private const SINGLE_STONE:String =			"single_stone_impact_0";
		private const SMALL_MULTI_STONE:String =	"multie_stone_impact_small_group_0";
		private const LARGE_MULTI_STONE:String =	"multie_stone_impact_large_group_0";
		private const BEETLE_FLIGHT:String =		"beetle_wings_01_loop.mp3";
		private const POINTS_PING:String =			"points_ping_01";
		private const MINI_GAME_WIN:String =		"MiniGameWin.mp3";
		private const MINI_GAME_LOSS:String =		"mini_game_loss.mp3";
		
		private var _playerTurnEnt:Entity;
		private var _coderTurnEnt:Entity;
		private var _scoreEnt:Entity;
	}
}