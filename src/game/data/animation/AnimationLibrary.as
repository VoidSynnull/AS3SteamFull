package game.data.animation 
{
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	
	import game.data.animation.entity.RigAnimationParser;
	import game.data.animation.entity.character.Default;
	
	/**
	 * Store a Dictionaries of Aniamtion classes, which are used by rig driven characters.
	 * @author Bard
	 */
	public class AnimationLibrary 
	{
		public function AnimationLibrary( shellApi:ShellApi ) 
		{
			_shellApi = shellApi;
			_animationLibraries = new Dictionary(true);
			_parser = new RigAnimationParser();
		}
		
		public function destroy():void
		{
			for each( var dict:Dictionary in _animationLibraries )
			{
				dict = null;
			}
			_animationLibraries = null;
			_shellApi = null;
		}
		
		public function getAnimation( animationClass:Class, type:String = CHARACTER ):*
		{
			var anim:Animation = getLibrary( type )[animationClass];
			
			if ( anim )
			{
				if ( anim.dataLoaded )	// don't return until AnimationData has been created/loaded
				{
					return anim;
				}
			}
			return null;
		}
		
		/**
		 * Instantiate animation class, loads xml, and adds to Dictionary if not yet added.
		 * Animation classes are shared across all entities that use this system
		 * @param	animationClass
		 * @param	type
		 */
		public function add( animationClass:Class, type:String = CHARACTER ):void
		{
			// get appropriate dictionary, proceed as normally
			_animations = getLibrary( type );
			
			if (!_animations[animationClass])
			{
				// TODO :: Need to load data xml as part of class instantiation, don't want to load twice
				
				var animation:* = new animationClass();
				_shellApi.injector.injectInto(animation);
				_animations[animationClass] = animation;
				
				var xmlPath:String = _shellApi.dataPrefix + getXmlPath( _animations[animationClass], type );
				_shellApi.loadFile( xmlPath, onXMLLoaded, _animations[animationClass] );
			}
		}
		
		private function onXMLLoaded( xml:XML, animation:Animation ):void
		{
			if( xml != null )
			{
				animation.init( _parser.parse(XML(xml)) );
			}
			else
			{
				trace( "Error :: AnimationLibrary :: xml not found for animation : " + animation );
			}
		}
		
		private function getLibrary( type:String ):Dictionary
		{
			if ( !_animationLibraries[type] )
			{
				var animDict:Dictionary = new Dictionary();
				_animationLibraries[type] = animDict;
				return _animationLibraries[type];
			}
			else
			{
				return _animationLibraries[type];
			}
		}
		

		private function getXmlPath ( animation:Default, type:String ):String
		{
			var xmlPath:String;
			switch( type )
			{
				case CHARACTER:
					xmlPath = animation.characterXmlPath;
					break;
				case CREATURE:
					xmlPath = ( animation.creatureXmlPath ) ? animation.creatureXmlPath : animation.characterXmlPath;
					break;
				case PET_BABYQUAD:
					xmlPath = ( animation.petBabyQuadXmlPath ) ? animation.petBabyQuadXmlPath : animation.characterXmlPath;
					break;
				case APE:
					xmlPath = ( animation.apeXmlPath ) ? animation.apeXmlPath : animation.characterXmlPath;
					break;
				case BIPED:
					xmlPath = ( animation.bipedXmlPath ) ? animation.bipedXmlPath : animation.characterXmlPath;
					break;					
				default:
					trace( "AnimationLibrary :: getXmlPath :: Error : There is no xml of type " + type );
			}
			return xmlPath;
		}

		public static const APE:String = "ape";
		public static const BIPED:String = "biped";
		public static const CHARACTER:String = "character";
		public static const CREATURE:String = "creature";
		public static const PET_BABYQUAD:String = "pet_babyquad";
		
		//[Inject]
		private var _shellApi:ShellApi;
		private var _animations:Dictionary;
		private var _animationLibraries:Dictionary;
		private var _parser:RigAnimationParser;
	}
}