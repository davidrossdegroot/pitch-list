## Problems
This repo contains a list of major problems for a particular region. The intent is to be a place to go to find "work" to do in that area that is meaningful and targets a particular problem for a particular region of the world.

### Definitions
- *Problem*: An issue that Washington DC faces such as climate change or mental health concern or poverty.
- *Pitch*: Each problem may have different "Pitches" associated to them. These roughly align to a ["shape-up pitch"](https://basecamp.com/shapeup). These contain small descriptions of the problem, the scope of the pitch, some data describing how this pitch will help, andd the solution. A pitch could belong to multiple problems. Generally pitches should take a small team of people 2-8 weeks to complete. E.g. A coffee shop helps prevent loneliness, and fights poverty with jobs. Each pitch should have opportunities to help people find grants, competitions (e.g. a competition for how to grow tomatoes with less waste), or other monetary opportunities (e.g. a coffee shop would provide monetary opportunity for a business owner).

### Why this helps
This seems like a pretty basic project but what makes this interesting is that it will be AI shepherded. At different intervals, jobs will run that could:
- add more pitch ideas
- analyze user created pitches and provide feedback via pull requests
- find associated opportunities

### Diagram
![Diagram of Repo + Actions + AI working together](diagram.png)

## Usage
- Fork this repo
- In your github action settings, create two environment variables: 
  - `REGION` - can be a [clear environment variable](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables). Can be set to any region you want to focus on. E.g. "Chicago", "Upper East Side, NYC", "Nepal" etc.
  - `OPENAI_API_KEY` - Should be a [github action repository secret](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) so others can't steal your api key and use it. Get this from the [Open AI API Dashboard](https://platform.openai.com/api-keys).
