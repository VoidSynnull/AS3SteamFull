package game.creators.entity.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.BitmapCharacter;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Talk;
	import game.components.motion.Edge;
	import game.components.render.PlatformDepthCollider;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdvertisingConstants;
	import game.data.character.CharacterData;
	import game.data.character.CharacterSceneData;
	import game.data.ui.ToolTipType;
	import game.util.CharUtils;
	import game.util.TimelineUtils;

	/**
	 * Creates a bitmap NPC entity
	 */
	public class BitmapCharacterCreator
	{
		public function createFromCharSceneData( group:Group, charSceneData:CharacterSceneData, container:DisplayObjectContainer = null ) : Entity
		{
			_scene = group;
			var charEntity : Entity = new Entity();
			

			// add BitmapCharacter
			var bitmapChar:BitmapCharacter 		= new BitmapCharacter();
			bitmapChar.id						= charSceneData.charId;
			bitmapChar._charSceneData 			= charSceneData;

			// if active character
			if( bitmapChar.type != CharacterCreator.TYPE_DUMMY )
			{
				// add Npc and set ignore depth to true (NPCs should always be behind avatar)
				var npc:Npc = new Npc();
				npc.ignoreDepth = true;
				charEntity.add(npc);
				
				charEntity.add(new PlatformDepthCollider());

				// setups up BitmapCharacter to listen for events, while using current events to define BitmapCharacter.
				// calls BitmapCharacter's eventTriggered, which defines nextCharData, type, & variant.
				group.shellApi.setupEventTrigger(bitmapChar);
			}
			var currentCharData:CharacterData = bitmapChar.nextCharData;
			charEntity.add(bitmapChar);

			// add Display
			var display : Display = new Display( new MovieClip(), container );
			display.moveToBack();
			charEntity.add( display );

			// add Spatial
			var spatial:Spatial = new Spatial();
			// set to normal scale of 1.0
			spatial.scaleX = spatial.scaleY = 1;
			if( currentCharData )
			{
				spatial.x = currentCharData.position.x;
				spatial.y = currentCharData.position.y;
			}
			charEntity.add( spatial );

			// add Dialog
			charEntity.add( new Dialog() );

			// add Id
			charEntity.add(new Id( charSceneData.charId ));

			// load external NPC
			// TODO :: This shoudl not be so Ad specific, want to make this more generic
			if( currentCharData )
			{
				var assetPath:String;
				var placeholder:Boolean = false;

				// TODO :: the path should really be determined ealier. - bard
				// if blank placeholder
				if (currentCharData.bitmap == "Blank.swf")
				{
					placeholder = true;
				}
				// if advertising (limited) path for swf
				else if (currentCharData.bitmap.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1)
				{
					assetPath = group.shellApi.assetPrefix + currentCharData.bitmap;
				}
				else
				{
					assetPath = group.shellApi.assetPrefix + "npcs/" + currentCharData.bitmap;
				}
				// if not placeholder for npc friend, then load file
				if (!placeholder)
					group.shellApi.loadFile( assetPath, NPCLoaded, charEntity);
			}

			// add OwningGroup
			charEntity.add( new OwningGroup( group ) );

			// add to group
			group.addEntity( charEntity );

			// if placeholder, then call NPCloaded right away
			if (placeholder)
				NPCLoaded(new MovieClip(), charEntity);

			return(charEntity);
		}

		/**
		 * When NPC finishes loading
		 */
		private function NPCLoaded( displayObject:MovieClip, charEntity:Entity ):void
		{
			// get character
			var bitmapChar:BitmapCharacter = charEntity.get(BitmapCharacter);

			// if no clip then skip
			if (displayObject == null)
			{
				bitmapChar.loadComplete.dispatch();
				return;
			}

			// set content
			var display : Display = charEntity.get(Display)
			display.displayObject = displayObject;
			display.setContainer( display.container );

			// since we are using a placeholder movieclip we need to set the position of the new displayObject manually as the renderSystem won't make changes to a displayObject that hasn't moved.
			var spatial:Spatial = charEntity.get(Spatial);
			displayObject.x = spatial.x;
			displayObject.y = spatial.y;

			// determine direction, flip is set to right
			var isFaceRight:Boolean = (bitmapChar.nextCharData.direction == CharUtils.DIRECTION_RIGHT);
			if (isFaceRight)
			{
				Spatial( charEntity.get(Spatial)).scaleX *= -1;
			}

			// set up edge based on bounds
			var edge:Edge = new Edge();
			edge.unscaled = displayObject.getBounds(displayObject);
			charEntity.add(edge);

			// set up dialog bubble position
			var dialog:Dialog = charEntity.get(Dialog);
			// enable/disable flipping to face speaker
			dialog.faceSpeaker = bitmapChar.nextCharData.faceSpeaker;
			charEntity.add( new Talk() );

			// if display Object has a bubble use it to define wordBalloon position
			// TODO :: this is very ad specific, would like to move it to separte class
			var bubbleClip:MovieClip = MovieClip(display.displayObject).bubble
			if ( bubbleClip != null)
			{
				var percentX:Number = bubbleClip.x/edge.rectangle.width;
				if (isFaceRight) 	// flip if facing to right
				{
					percentX *= -1;
				}
				var percentY:Number = ( -bubbleClip.y + 12 )/-edge.rectangle.top;
				dialog.dialogPositionPercents = new Point(percentX, percentY);
			}
			else
			{
				// the bottom of the word bubble clears the top of the bitmap by 12 pixels
				dialog.dialogPositionPercents = new Point(0, 1);
			}

			// convert breathing NPC to timeline if not one frame
			// NOTE: if the npc instance within the loaded swf is not named "npc" then you will get an error here!!!!
			// TODO :: this needs some work. - bard
			var npcClip:MovieClip = MovieClip(display.displayObject).npc
			if( npcClip )
			{
				if ( npcClip.totalFrames != 1)
				{
					TimelineUtils.convertClip( npcClip, _scene, charEntity );
				}
			}

			// add interaction for npc
			var interaction:Interaction = InteractionCreator.addToEntity(charEntity, [InteractionCreator.CLICK]);
			// NOTE :: currently click handlers are being set within AdSceneGroup

			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetX = edge.rectangle.width/2 + 30;	// set offset to half width plus 30
			sceneInteraction.offsetY = 0;
			sceneInteraction.offsetDirection = true;	// have interacting entity face bitmap char
			charEntity.add(sceneInteraction);

			// RLH: add tooltip
			ToolTipCreator.addToEntity(charEntity, ToolTipType.CLICK);
			
			// signal that bitmap NPC is loaded
			bitmapChar.loadComplete.dispatch();
		}

		private var _scene:Group;
	}
}
