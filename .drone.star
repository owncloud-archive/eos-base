config = {
  'eos_version': '4.8.26',
  'xrd_version': '4.12.5',
}

def main(ctx):
    stages = []
    stages.append(docker(ctx, 'eos-base'))
    
    return stages

def docker(ctx, image):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'docker-%s' % (image),
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'dryrun',
        'image': 'plugins/docker:18.09',
        'pull': 'always',
        'settings': {
          'dry_run': True,
          'context': '%s' % (image),
          'dockerfile': '%s/Dockerfile' % (image),
          'repo': ctx.repo.slug,
          'build_args': [
            'EOS_VERSION=%s' % (config['eos_version']),
            'XRD_VERSION=%s' % (config['xrd_version']),
          ],
        },
        'when': {
        'ref': {
            'include': [
              'refs/pull/**',
            ],
          },
        },
      },
      {
        'name': 'docker',
        'image': 'plugins/docker:18.09',
        'pull': 'always',
        'settings': {
          'username': {
          'from_secret': 'public_username',
          },
          'password': {
          'from_secret': 'public_password',
          },
          'auto_tag': True,
          'context': '%s' % (image),
          'dockerfile': '%s/Dockerfile' % (image),
          'repo': 'owncloud/%s' % (ctx.repo.slug.replace("owncloud-docker/", "")),
          'build_args': [
            'EOS_VERSION=%s' % (ctx.build.ref.replace("refs/tags/v", "") if ctx.build.event == 'tag' else config['eos_version']),
            'XRD_VERSION=%s' % (config['xrd_version']),
          ],
        },
        'when': {
            'ref': {
                'exclude': [
                  'refs/pull/**',
                ],
            },
        },
      },
    ],
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/main',
        'refs/tags/v*',
        'refs/pull/**',
      ],
    },
  }